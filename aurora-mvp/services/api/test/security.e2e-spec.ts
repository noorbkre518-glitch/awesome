import { Test } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

function idFromToken(t: string): string {
  return JSON.parse(Buffer.from(t.split('.')[1], 'base64').toString()).sub;
}

/**
 * Security & session invalidation suite. These are the P0 guarantees:
 *  - a valid signature is not enough; live account state is re-checked;
 *  - deleting the account kills the token immediately (not after 15 min);
 *  - logout invalidates the session;
 *  - suspended users are locked out and cannot message.
 */
describe('Aurora security & sessions (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const stamp = Date.now();

  const reg = (n: string) =>
    request(app.getHttpServer()).post('/api/auth/register').send({
      email: `sec_${n}_${stamp}@aurora.test`,
      password: 'password123',
      dateOfBirth: '1994-03-03',
      displayName: `Sec${n}`,
    });

  const auth = (path: string, tok: string) =>
    request(app.getHttpServer()).get(path).set('Authorization', `Bearer ${tok}`);

  beforeAll(async () => {
    const mod = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = mod.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
    );
    await app.init();
    prisma = app.get(PrismaService);
  });

  afterAll(async () => {
    await prisma.user.deleteMany({
      where: {
        OR: [
          { email: { contains: '@aurora.test' } },
          { email: { contains: '@aurora.invalid' } },
        ],
      },
    });
    await app.close();
  });

  it('access token works BEFORE deletion and fails IMMEDIATELY after deletion', async () => {
    const tok = (await reg('del').expect(201)).body.accessToken as string;
    // Works before deletion.
    await auth('/api/profiles/me', tok).expect(200);
    // Delete the account with that same token.
    await request(app.getHttpServer())
      .delete('/api/users/me')
      .set('Authorization', `Bearer ${tok}`)
      .expect(200);
    // The very same (still unexpired) token is now rejected everywhere.
    await auth('/api/profiles/me', tok).expect(401);
    await auth('/api/discovery', tok).expect(401);
    await auth('/api/interactions/matches', tok).expect(401);
  });

  it('deleted account cannot log in again', async () => {
    const email = `sec_del_${stamp}@aurora.test`;
    await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email, password: 'password123' })
      .expect(401);
  });

  it('logout invalidates the session; a fresh login still works', async () => {
    const email = `sec_logout_${stamp}@aurora.test`;
    const tok = (await reg('logout').expect(201)).body.accessToken as string;
    await auth('/api/profiles/me', tok).expect(200);

    // Real logout: server bumps tokenVersion.
    await request(app.getHttpServer())
      .post('/api/auth/logout')
      .set('Authorization', `Bearer ${tok}`)
      .expect(200);

    // Old token is dead now.
    await auth('/api/profiles/me', tok).expect(401);

    // But the user can log in again and get a working token.
    const tok2 = (
      await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email, password: 'password123' })
        .expect(200)
    ).body.accessToken as string;
    await auth('/api/profiles/me', tok2).expect(200);
  });

  it('a suspended user is locked out and cannot message', async () => {
    const tokX = (await reg('susX').expect(201)).body.accessToken as string;
    const tokY = (await reg('susY').expect(201)).body.accessToken as string;
    const idX = idFromToken(tokX);
    const idY = idFromToken(tokY);

    // Mutual like → match.
    await request(app.getHttpServer())
      .post('/api/interactions/like')
      .set('Authorization', `Bearer ${tokX}`)
      .send({ targetUserId: idY })
      .expect(201);
    const match = await request(app.getHttpServer())
      .post('/api/interactions/like')
      .set('Authorization', `Bearer ${tokY}`)
      .send({ targetUserId: idX })
      .expect(201);
    const matchId = match.body.matchId as string;

    // Messaging works before suspension.
    await request(app.getHttpServer())
      .post('/api/messaging/send')
      .set('Authorization', `Bearer ${tokX}`)
      .send({ matchId, body: 'hi before suspension' })
      .expect(201);

    // Suspend X (as a moderation action would).
    await prisma.user.update({
      where: { id: idX },
      data: { isSuspended: true, suspendedAt: new Date(), tokenVersion: { increment: 1 } },
    });

    // X can no longer reach protected endpoints, including messaging.
    await request(app.getHttpServer())
      .post('/api/messaging/send')
      .set('Authorization', `Bearer ${tokX}`)
      .send({ matchId, body: 'still here?' })
      .expect(401);
    await auth('/api/discovery', tokX).expect(401);

    // A suspended account cannot obtain a fresh token either.
    await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: `sec_susX_${stamp}@aurora.test`, password: 'password123' })
      .expect(401);

    // The still-active partner cannot message a suspended user.
    await request(app.getHttpServer())
      .post('/api/messaging/send')
      .set('Authorization', `Bearer ${tokY}`)
      .send({ matchId, body: 'you there?' })
      .expect(403);
  });

  it('moderation ACTIONED suspends the reported user end-to-end', async () => {
    const tokReporter = (await reg('modR').expect(201)).body.accessToken as string;
    const tokTarget = (await reg('modT').expect(201)).body.accessToken as string;
    const tokAdmin = (await reg('modA').expect(201)).body.accessToken as string;
    const idTarget = idFromToken(tokTarget);
    const idAdmin = idFromToken(tokAdmin);

    // Reporter files a report against target.
    const rep = await request(app.getHttpServer())
      .post('/api/users/report')
      .set('Authorization', `Bearer ${tokReporter}`)
      .send({ targetUserId: idTarget, reason: 'harassment', details: 'abuse' })
      .expect(201);
    const reportId = rep.body.reportId as string;

    // Elevate a user to ADMIN (guard reads role from the DB, so the token gains it).
    await prisma.user.update({ where: { id: idAdmin }, data: { role: 'ADMIN' } });

    // Admin actions the report → target gets suspended.
    await request(app.getHttpServer())
      .patch(`/api/admin/reports/${reportId}`)
      .set('Authorization', `Bearer ${tokAdmin}`)
      .send({ status: 'ACTIONED' })
      .expect(200);

    const target = await prisma.user.findUnique({ where: { id: idTarget } });
    expect(target?.isSuspended).toBe(true);

    // Target is now locked out.
    await auth('/api/discovery', tokTarget).expect(401);
  });

  it('de-duplicates repeated reports of the same user while unresolved', async () => {
    const tokReporter = (await reg('dupR').expect(201)).body.accessToken as string;
    const tokTarget = (await reg('dupT').expect(201)).body.accessToken as string;
    const idTarget = idFromToken(tokTarget);

    const first = await request(app.getHttpServer())
      .post('/api/users/report')
      .set('Authorization', `Bearer ${tokReporter}`)
      .send({ targetUserId: idTarget, reason: 'spam' })
      .expect(201);
    const second = await request(app.getHttpServer())
      .post('/api/users/report')
      .set('Authorization', `Bearer ${tokReporter}`)
      .send({ targetUserId: idTarget, reason: 'spam again' })
      .expect(201);

    expect(second.body.reportId).toBe(first.body.reportId);
    expect(second.body.duplicate).toBe(true);

    const count = await prisma.report.count({
      where: { reporterId: idFromToken(tokReporter), reportedId: idTarget },
    });
    expect(count).toBe(1);
  });

  it('rejects tampered / unsigned tokens', async () => {
    // Well-formed but wrong-signature token.
    const bogus =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' +
      'eyJzdWIiOiJ4Iiwicm9sZSI6IkFETUlOIiwidHYiOjB9.' +
      'not-a-valid-signature';
    await auth('/api/profiles/me', bogus).expect(401);
    await request(app.getHttpServer()).get('/api/profiles/me').expect(401);
  });
});
