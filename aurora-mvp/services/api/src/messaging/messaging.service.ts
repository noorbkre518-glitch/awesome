import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MessagingService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Enforces that `userId` may act on `matchId`:
   *  - the match exists and the caller is one of its two participants;
   *  - no block is in effect in either direction.
   * Returns the match plus the other participant's id.
   */
  private async requireMembership(userId: string, matchId: string) {
    const match = await this.prisma.match.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('Match not found');
    if (match.userAId !== userId && match.userBId !== userId) {
      throw new ForbiddenException('Not a participant of this match');
    }
    // Block check: if either party blocked the other, messaging is disabled.
    const otherId = match.userAId === userId ? match.userBId : match.userAId;
    const blocked = await this.prisma.block.findFirst({
      where: {
        OR: [
          { blockerId: userId, blockedId: otherId },
          { blockerId: otherId, blockedId: userId },
        ],
      },
    });
    if (blocked) throw new ForbiddenException('Messaging disabled (block in effect)');
    return { match, otherId };
  }

  async send(userId: string, matchId: string, body: string) {
    const { otherId } = await this.requireMembership(userId, matchId);
    // Cannot send into a conversation whose other party deleted or is suspended.
    const other = await this.prisma.user.findUnique({
      where: { id: otherId },
      select: { isDeleted: true, isSuspended: true },
    });
    if (!other || other.isDeleted) {
      throw new ForbiddenException('This user is no longer available');
    }
    if (other.isSuspended) {
      throw new ForbiddenException('Messaging is disabled for this conversation');
    }
    const msg = await this.prisma.message.create({
      data: { matchId, senderId: userId, body },
    });
    return { id: msg.id, matchId, senderId: userId, body: msg.body, createdAt: msg.createdAt };
  }

  async list(userId: string, matchId: string) {
    // Reading existing history stays allowed even if the other party has left,
    // so the caller can still see the conversation they participated in.
    await this.requireMembership(userId, matchId);
    const msgs = await this.prisma.message.findMany({
      where: { matchId },
      orderBy: { createdAt: 'asc' },
      take: 200,
    });
    return msgs.map((m) => ({
      id: m.id,
      senderId: m.senderId,
      body: m.body,
      mine: m.senderId === userId,
      createdAt: m.createdAt,
    }));
  }
}
