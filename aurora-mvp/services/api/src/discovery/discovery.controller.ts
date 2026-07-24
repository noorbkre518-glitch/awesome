import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { DiscoveryService } from './discovery.service';

@Controller('discovery')
@UseGuards(JwtGuard)
export class DiscoveryController {
  constructor(private readonly discovery: DiscoveryService) {}

  @Get()
  candidates(@Req() req: any) {
    return this.discovery.candidates(req.user.sub);
  }
}
