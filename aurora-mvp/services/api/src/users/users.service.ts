import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Account deletion — Master Plan §24-ب. Anonymize the record, drop the
   * profile, and bump tokenVersion so the current access token dies immediately
   * (the guard also rejects on isDeleted, so this is defence in depth).
   */
  async deleteAccount(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.isDeleted) throw new NotFoundException('User not found');

    await this.prisma.$transaction([
      this.prisma.profile.deleteMany({ where: { userId } }),
      this.prisma.user.update({
        where: { id: userId },
        data: {
          isDeleted: true,
          deletedAt: new Date(),
          tokenVersion: { increment: 1 },
          email: `deleted+${userId}@aurora.invalid`,
          passwordHash: 'deleted',
          dateOfBirth: new Date('1900-01-01'),
        },
      }),
    ]);
    return { deleted: true, userId };
  }

  async block(blockerId: string, targetUserId: string) {
    if (blockerId === targetUserId) throw new BadRequestException('Cannot block yourself');
    const target = await this.prisma.user.findFirst({
      where: { id: targetUserId, isDeleted: false },
    });
    if (!target) throw new NotFoundException('Target user not found');
    await this.prisma.block.upsert({
      where: { blockerId_blockedId: { blockerId, blockedId: targetUserId } },
      create: { blockerId, blockedId: targetUserId },
      update: {},
    });
    return { blocked: true, targetUserId };
  }

  async report(reporterId: string, targetUserId: string, reason: string, details: string) {
    if (reporterId === targetUserId) throw new BadRequestException('Cannot report yourself');
    const target = await this.prisma.user.findFirst({
      where: { id: targetUserId, isDeleted: false },
    });
    if (!target) throw new NotFoundException('Target user not found');

    // Abuse guard: collapse repeat reports of the same user while an earlier one
    // is still unresolved, instead of letting a reporter spam the queue.
    const existingOpen = await this.prisma.report.findFirst({
      where: {
        reporterId,
        reportedId: targetUserId,
        status: { in: ['OPEN', 'UNDER_REVIEW'] },
      },
    });
    if (existingOpen) {
      return { reported: true, reportId: existingOpen.id, duplicate: true };
    }

    const report = await this.prisma.report.create({
      data: { reporterId, reportedId: targetUserId, reason, details },
    });
    return { reported: true, reportId: report.id, duplicate: false };
  }
}
