import { Body, Controller, Delete, Post, Req, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtGuard } from '../auth/jwt.guard';
import { UsersService } from './users.service';
import { BlockDto, ReportDto } from './dto';

@Controller('users')
@UseGuards(JwtGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Delete('me')
  deleteMe(@Req() req: any) {
    return this.users.deleteAccount(req.user.sub);
  }

  @Post('block')
  block(@Req() req: any, @Body() dto: BlockDto) {
    return this.users.block(req.user.sub, dto.targetUserId);
  }

  // Report flooding guard: cap how many reports one account can file per minute
  // (the service also de-duplicates repeat reports of the same user).
  @Post('report')
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  report(@Req() req: any, @Body() dto: ReportDto) {
    return this.users.report(req.user.sub, dto.targetUserId, dto.reason, dto.details);
  }
}
