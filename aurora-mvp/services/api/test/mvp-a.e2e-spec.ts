import { Test } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

function idFromToken(t: string): string {
  return JSON.parse(Buffer.from(t.split('.')[1], 'base64').toString()).sub;
}

describe('Aurora MVP-A social (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const stamp = Date.now();
  let tokA: string, tokB: string, tokC: string;
  let idA: string, idB: string, idC: string;

  const reg = (n: string) =>
    request(app.getHttpServer()).post('/api/auth/register').send({
      email: `mvpa_${n}_${stamp}@aurora.test`,
      password: 'password123',
      dateOfBirth: '1993-04-04',
      displayName: `User${n}`,
    });

  beforeAll(async () => {
    const mod = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = mod.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.init();
    prisma = app.get(PrismaService);
    tokA = (await reg('A').expect(201)).body.accessToken; idA = idFromToken(tokA);
    tokB = (await reg('B').expect(201)).body.accessToken; idB = idFromToken(tokB);
    tokC = (await reg('C').expect(201)).body.accessToken; idC = idFromToken(tokC);
  });

  afterAll(async () => {
    await prisma.user.deleteMany({ where: { email: { contains: '@aurora.test' } } });
    await app.close();
  });

  it('discovery lists other users, excludes self', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/discovery').set('Authorization', `Bearer ${tokA}`).expect(200);
    const ids = res.body.map((c: any) => c.userId);
    expect(ids).not.toContain(idA);
    expect(ids).toContain(idB);
  });

  it('A likes B → no match yet', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/interactions/like').set('Authorization', `Bearer ${tokA}`)
      .send({ targetUserId: idB }).expect(201);
    expect(res.body).toMatchObject({ liked: true, matched: false });
  });

  it('liked user no longer appears in discovery', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/discovery').set('Authorization', `Bearer ${tokA}`).expect(200);
    expect(res.body.map((c: any) => c.userId)).not.toContain(idB);
  });

  let matchId: string;
  it('B likes A back → match created', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/interactions/like').set('Authorization', `Bearer ${tokB}`)
      .send({ targetUserId: idA, kind: 'SUPER_LIKE' }).expect(201);
    expect(res.body.matched).toBe(true);
    expect(res.body.matchId).toBeDefined();
    matchId = res.body.matchId;
  });

  it('both see the match', async () => {
    const a = await request(app.getHttpServer()).get('/api/interactions/matches').set('Authorization', `Bearer ${tokA}`).expect(200);
    const b = await request(app.getHttpServer()).get('/api/interactions/matches').set('Authorization', `Bearer ${tokB}`).expect(200);
    expect(a.body.map((m: any) => m.matchId)).toContain(matchId);
    expect(b.body.map((m: any) => m.matchId)).toContain(matchId);
    expect(a.body.find((m: any) => m.matchId === matchId).otherUserId).toBe(idB);
  });

  it('A and B exchange messages in the match', async () => {
    await request(app.getHttpServer()).post('/api/messaging/send').set('Authorization', `Bearer ${tokA}`)
      .send({ matchId, body: 'مرحبا' }).expect(201);
    await request(app.getHttpServer()).post('/api/messaging/send').set('Authorization', `Bearer ${tokB}`)
      .send({ matchId, body: 'أهلا' }).expect(201);
    const thread = await request(app.getHttpServer()).get(`/api/messaging/${matchId}`).set('Authorization', `Bearer ${tokA}`).expect(200);
    expect(thread.body.length).toBe(2);
    expect(thread.body[0]).toMatchObject({ body: 'مرحبا', mine: true });
    expect(thread.body[1]).toMatchObject({ body: 'أهلا', mine: false });
  });

  it('non-participant C cannot read the match thread', async () => {
    await request(app.getHttpServer()).get(`/api/messaging/${matchId}`).set('Authorization', `Bearer ${tokC}`).expect(403);
  });

  it('block disables messaging', async () => {
    await request(app.getHttpServer()).post('/api/users/block').set('Authorization', `Bearer ${tokA}`)
      .send({ targetUserId: idB }).expect(201);
    await request(app.getHttpServer()).post('/api/messaging/send').set('Authorization', `Bearer ${tokA}`)
      .send({ matchId, body: 'blocked?' }).expect(403);
  });

  it('cannot like yourself', async () => {
    await request(app.getHttpServer()).post('/api/interactions/like').set('Authorization', `Bearer ${tokC}`)
      .send({ targetUserId: idC }).expect(400);
  });
});
