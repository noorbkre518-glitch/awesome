import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtGuard } from './jwt.guard';

const DEV_FALLBACK_SECRET = 'dev-only-insecure-secret-change-me';

@Module({
  imports: [
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => {
        const secret = cfg.get<string>('JWT_SECRET');
        const isProd = cfg.get<string>('NODE_ENV') === 'production';
        // Never boot production with a missing or placeholder signing secret.
        if (isProd && (!secret || secret === DEV_FALLBACK_SECRET || secret === 'change-me-in-production')) {
          throw new Error(
            'JWT_SECRET must be set to a strong, non-default value in production.',
          );
        }
        return {
          secret: secret ?? DEV_FALLBACK_SECRET,
          signOptions: { expiresIn: '15m' },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtGuard],
  exports: [JwtGuard, JwtModule],
})
export class AuthModule {}
