import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtGuard } from '../auth/jwt.guard';
import { MessagingService } from './messaging.service';
import { SendMessageDto } from './dto';

@Controller('messaging')
@UseGuards(JwtGuard)
export class MessagingController {
  constructor(private readonly messaging: MessagingService) {}

  // Cap message send rate per account to curb spam/flooding.
  @Post('send')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  send(@Req() req: any, @Body() dto: SendMessageDto) {
    return this.messaging.send(req.user.sub, dto.matchId, dto.body);
  }

  @Get(':matchId')
  list(@Req() req: any, @Param('matchId') matchId: string) {
    return this.messaging.list(req.user.sub, matchId);
  }
}
