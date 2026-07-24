import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { PrismaService } from '../prisma/prisma.service';
import { isAdult } from '../common/age';
import { RegisterDto, LoginDto } from './dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const dob = new Date(dto.dateOfBirth);
    if (isNaN(dob.getTime())) {
      throw new BadRequestException('Invalid dateOfBirth');
    }
    // Age gate — Master Plan §6/§32: adults 18+ only.
    if (!isAdult(dob)) {
      throw new BadRequestException('You must be at least 18 years old to register');
    }
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException('Email already registered');
    }
    const passwordHash = await argon2.hash(dto.password);
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        passwordHash,
        dateOfBirth: dob,
        isAdult: true,
        profile: { create: { displayName: dto.displayName } },
      },
      include: { profile: true },
    });
    return this.issueTokens(user.id, user.email, user.role, user.tokenVersion);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    // Identical error for missing/deleted/wrong-password so we never reveal which
    // emails exist. Suspended accounts get a distinct, non-sensitive message.
    if (!user || user.isDeleted) {
      throw new UnauthorizedException('Invalid credentials');
    }
    const ok = await argon2.verify(user.passwordHash, dto.password);
    if (!ok) {
      throw new UnauthorizedException('Invalid credentials');
    }
    if (user.isSuspended) {
      throw new UnauthorizedException('Account is suspended');
    }
    return this.issueTokens(user.id, user.email, user.role, user.tokenVersion);
  }

  /**
   * Real logout: bump the user's tokenVersion so every previously issued access
   * token is rejected by the guard on its next use (all devices/sessions).
   */
  async logout(userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { tokenVersion: { increment: 1 } },
    });
    return { loggedOut: true };
  }

  private async issueTokens(
    userId: string,
    email: string,
    role: string,
    tokenVersion: number,
  ) {
    const accessToken = await this.jwt.signAsync(
      { sub: userId, email, role, tv: tokenVersion },
      { expiresIn: '15m' },
    );
    return { accessToken, tokenType: 'Bearer', expiresIn: 900 };
  }
}
