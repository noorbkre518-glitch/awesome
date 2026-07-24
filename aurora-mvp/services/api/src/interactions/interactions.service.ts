import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class InteractionsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Record a like; if the target already liked me, create a Match. Master Plan §8.
   *  Ordered pair (userAId < userBId) keeps Match unique regardless of who liked first. */
  async like(fromId: string, targetUserId: string, kind: 'LIKE' | 'SUPER_LIKE' = 'LIKE') {
    if (fromId === targetUserId) throw new BadRequestException('Cannot like yourself');
    const target = await this.prisma.user.findFirst({
      where: { id: targetUserId, isDeleted: false, isSuspended: false },
    });
    if (!target) throw new NotFoundException('Target user not found');

    // Respect blocks in either direction.
    const blocked = await this.prisma.block.findFirst({
      where: {
        OR: [
          { blockerId: fromId, blockedId: targetUserId },
          { blockerId: targetUserId, blockedId: fromId },
        ],
      },
    });
    if (blocked) throw new ForbiddenException('Interaction not allowed');

    await this.prisma.like.upsert({
      where: { fromId_toId: { fromId, toId: targetUserId } },
      create: { fromId, toId: targetUserId, kind },
      update: { kind },
    });

    const reciprocal = await this.prisma.like.findUnique({
      where: { fromId_toId: { fromId: targetUserId, toId: fromId } },
    });

    if (reciprocal) {
      const [a, b] = [fromId, targetUserId].sort();
      const match = await this.prisma.match.upsert({
        where: { userAId_userBId: { userAId: a, userBId: b } },
        create: { userAId: a, userBId: b },
        update: {},
      });
      return { liked: true, matched: true, matchId: match.id };
    }
    return { liked: true, matched: false };
  }

  async myMatches(userId: string) {
    const matches = await this.prisma.match.findMany({
      where: { OR: [{ userAId: userId }, { userBId: userId }] },
      orderBy: { createdAt: 'desc' },
      include: {
        userA: { select: { id: true, profile: { select: { displayName: true } } } },
        userB: { select: { id: true, profile: { select: { displayName: true } } } },
      },
    });
    return matches.map((m) => {
      const other = m.userAId === userId ? m.userB : m.userA;
      return { matchId: m.id, otherUserId: other.id, otherName: other.profile?.displayName ?? 'Unknown' };
    });
  }
}
