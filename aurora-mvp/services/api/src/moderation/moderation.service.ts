import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

const RESOLUTIONS = ['UNDER_REVIEW', 'ACTIONED', 'DISMISSED'] as const;
type Resolution = (typeof RESOLUTIONS)[number];

@Injectable()
export class ModerationService {
  constructor(private readonly prisma: PrismaService) {}

  private ensureStaff(role: string) {
    if (role !== 'ADMIN' && role !== 'MODERATOR') {
      throw new ForbiddenException('Staff only');
    }
  }

  async listReports(role: string) {
    this.ensureStaff(role);
    return this.prisma.report.findMany({ orderBy: { createdAt: 'desc' }, take: 100 });
  }

  async setStatus(role: string, id: string, status: string) {
    this.ensureStaff(role);
    if (!RESOLUTIONS.includes(status as Resolution)) {
      throw new BadRequestException('Invalid status');
    }
    const report = await this.prisma.report.findUnique({ where: { id } });
    if (!report) throw new NotFoundException('Report not found');

    // DISMISSED resolves only this report. It must never lift a suspension
    // created by another report or by a separate administrative decision.
    if (status === 'ACTIONED') {
      await this.prisma.user.update({
        where: { id: report.reportedId },
        data: { isSuspended: true, suspendedAt: new Date(), tokenVersion: { increment: 1 } },
      });
    }

    return this.prisma.report.update({ where: { id }, data: { status: status as Resolution } });
  }
}
