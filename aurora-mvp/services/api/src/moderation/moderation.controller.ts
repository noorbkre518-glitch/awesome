import { Body, Controller, Get, Param, Patch, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { ModerationService } from './moderation.service';

@Controller('admin/reports')
@UseGuards(JwtGuard)
export class ModerationController {
  constructor(private readonly moderation: ModerationService) {}

  @Get()
  list(@Req() req: any) {
    return this.moderation.listReports(req.user.role);
  }

  @Patch(':id')
  setStatus(@Req() req: any, @Param('id') id: string, @Body('status') status: string) {
    return this.moderation.setStatus(req.user.role, id, status);
  }
}
