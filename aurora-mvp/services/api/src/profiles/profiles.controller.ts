import { Body, Controller, Get, Patch, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { ProfilesService } from './profiles.service';
import { UpdateProfileDto } from './dto';

@Controller('profiles')
@UseGuards(JwtGuard)
export class ProfilesController {
  constructor(private readonly profiles: ProfilesService) {}

  @Get('me')
  getMine(@Req() req: any) {
    return this.profiles.getMine(req.user.sub);
  }

  @Patch('me')
  updateMine(@Req() req: any, @Body() dto: UpdateProfileDto) {
    return this.profiles.updateMine(req.user.sub, dto);
  }
}
