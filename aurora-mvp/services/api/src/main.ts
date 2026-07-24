import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

/**
 * CORS origins:
 *  - CORS_ORIGIN unset            → reflect request origin (convenient for local dev).
 *  - CORS_ORIGIN="*"              → allow any origin.
 *  - CORS_ORIGIN="a.com,b.com"    → allow only those origins (recommended for prod).
 * Note: native mobile clients don't send an Origin header, so CORS never blocks them.
 */
function resolveCorsOrigin(): boolean | string[] {
  const raw = process.env.CORS_ORIGIN?.trim();
  if (!raw) return true;
  if (raw === '*') return true;
  return raw.split(',').map((o) => o.trim()).filter(Boolean);
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
  );
  app.enableCors({ origin: resolveCorsOrigin(), credentials: false });
  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  // eslint-disable-next-line no-console
  console.log(`Aurora API listening on :${port}`);
}
bootstrap();
