import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { InteractionsService } from './interactions.service';
import { LikeDto } from './dto';

@Controller('interactions')
@UseGuards(JwtGuard)
export class InteractionsController {
  constructor(private readonly interactions: InteractionsService) {}

  @Post('like')
  like(@Req() req: any, @Body() dto: LikeDto) {
    return this.interactions.like(req.user.sub, dto.targetUserId, dto.kind ?? 'LIKE');
  }

  @Get('matches')
  matches(@Req() req: any) {
    return this.interactions.myMatches(req.user.sub);
  }
}
