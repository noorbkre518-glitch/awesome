import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Authenticates protected requests. A valid signature is NOT enough: on every
 * request we re-check the live account state so a token stops working the
 * moment the account is deleted, suspended, or its session is invalidated.
 *
 * Checks performed:
 *  1. Bearer token present and signature/expiry valid.
 *  2. The user still exists and is not soft-deleted.
 *  3. The user is not suspended.
 *  4. The token's `tv` (token version) matches the user's current tokenVersion
 *     — logout and account deletion bump tokenVersion, invalidating old tokens
 *     immediately (not after the 15-minute access-token expiry).
 */
@Injectable()
export class JwtGuard implements CanActivate {
  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const req = ctx.switchToHttp().getRequest();
    const header: string | undefined = req.headers['authorization'];
    if (!header?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing bearer token');
    }

    let payload: { sub?: string; email?: string; role?: string; tv?: number };
    try {
      payload = await this.jwt.verifyAsync(header.slice(7));
    } catch {
      throw new UnauthorizedException('Invalid token');
    }

    if (!payload?.sub) {
      throw new UnauthorizedException('Invalid token');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        email: true,
        role: true,
        isDeleted: true,
        isSuspended: true,
        tokenVersion: true,
      },
    });

    if (!user || user.isDeleted) {
      throw new UnauthorizedException('Account is no longer active');
    }
    if (user.isSuspended) {
      throw new UnauthorizedException('Account is suspended');
    }
    if ((payload.tv ?? -1) !== user.tokenVersion) {
      throw new UnauthorizedException('Session expired, please sign in again');
    }

    // Attach a fresh, trustworthy identity (role comes from the DB, not the token).
    req.user = { sub: user.id, id: user.id, email: user.email, role: user.role };
    return true;
  }
}
