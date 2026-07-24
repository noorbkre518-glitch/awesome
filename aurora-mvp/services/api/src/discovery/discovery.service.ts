import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DiscoveryService {
  constructor(private readonly prisma: PrismaService) {}

  /** Candidate profiles for discovery — excludes self, deleted, suspended, blocked
   *  (either direction), and users already liked by me. Master Plan §8. */
  async candidates(userId: string, take = 20) {
    const [blocksMade, blocksReceived, liked] = await Promise.all([
      this.prisma.block.findMany({ where: { blockerId: userId }, select: { blockedId: true } }),
      this.prisma.block.findMany({ where: { blockedId: userId }, select: { blockerId: true } }),
      this.prisma.like.findMany({ where: { fromId: userId }, select: { toId: true } }),
    ]);
    const excluded = new Set<string>([
      userId,
      ...blocksMade.map((b) => b.blockedId),
      ...blocksReceived.map((b) => b.blockerId),
      ...liked.map((l) => l.toId),
    ]);
    const users = await this.prisma.user.findMany({
      where: { isDeleted: false, isSuspended: false, id: { notIn: Array.from(excluded) } },
      select: { id: true, profile: { select: { displayName: true, bio: true, country: true } } },
      take,
      orderBy: { createdAt: 'desc' },
    });
    return users
      .filter((u) => u.profile)
      .map((u) => ({
        userId: u.id,
        displayName: u.profile!.displayName,
        bio: u.profile!.bio,
        country: u.profile!.country,
      }));
  }
}
