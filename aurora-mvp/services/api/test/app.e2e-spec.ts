import { Test } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Aurora base slice (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const email = `user_${Date.now()}@aurora.test`;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.init();
    prisma = app.get(PrismaService);
  });

  afterAll(async () => {
    await prisma.user.deleteMany({ where: { email: { contains: '@aurora.test' } } });
    await app.close();
  });

  it('GET /api/health → ok + db up', async () => {
    const res = await request(app.getHttpServer()).get('/api/health').expect(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.db).toBe('up');
  });

  it('rejects registration under 18', async () => {
    await request(app.getHttpServer())
      .post('/api/auth/register')
      .send({ email: `minor_${Date.now()}@aurora.test`, password: 'password123', dateOfBirth: '2015-01-01', displayName: 'Minor' })
      .expect(400);
  });

  let token: string;
  it('registers an adult and returns a token', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/auth/register')
      .send({ email, password: 'password123', dateOfBirth: '1995-06-15', displayName: 'Nour' })
      .expect(201);
    expect(res.body.accessToken).toBeDefined();
    token = res.body.accessToken;
  });

  it('rejects duplicate email', async () => {
    await request(app.getHttpServer())
      .post('/api/auth/register')
      .send({ email, password: 'password123', dateOfBirth: '1995-06-15', displayName: 'Dup' })
      .expect(409);
  });

  it('logs in with correct password', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email, password: 'password123' })
      .expect(200);
    expect(res.body.accessToken).toBeDefined();
  });

  it('rejects wrong password', async () => {
    await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email, password: 'wrongpass' })
      .expect(401);
  });

  it('blocks unauthenticated profile access', async () => {
    await request(app.getHttpServer()).get('/api/profiles/me').expect(401);
  });

  it('reads and updates own profile', async () => {
    const me = await request(app.getHttpServer())
      .get('/api/profiles/me').set('Authorization', `Bearer ${token}`).expect(200);
    expect(me.body.displayName).toBe('Nour');
    const upd = await request(app.getHttpServer())
      .patch('/api/profiles/me').set('Authorization', `Bearer ${token}`)
      .send({ bio: 'Hello Aurora', country: 'NL' }).expect(200);
    expect(upd.body.bio).toBe('Hello Aurora');
    expect(upd.body.country).toBe('NL');
  });

  it('files a report against another user', async () => {
    const other = await request(app.getHttpServer())
      .post('/api/auth/register')
      .send({ email: `other_${Date.now()}@aurora.test`, password: 'password123', dateOfBirth: '1992-02-02', displayName: 'Other' })
      .expect(201);
    const otherId = (JSON.parse(Buffer.from(other.body.accessToken.split('.')[1], 'base64').toString())).sub;
    const rep = await request(app.getHttpServer())
      .post('/api/users/report').set('Authorization', `Bearer ${token}`)
      .send({ targetUserId: otherId, reason: 'spam', details: 'test report' }).expect(201);
    expect(rep.body.reported).toBe(true);
    // block same user
    await request(app.getHttpServer())
      .post('/api/users/block').set('Authorization', `Bearer ${token}`)
      .send({ targetUserId: otherId }).expect(201);
  });

  it('deletes own account and revokes access', async () => {
    const res = await request(app.getHttpServer())
      .delete('/api/users/me').set('Authorization', `Bearer ${token}`).expect(200);
    expect(res.body.deleted).toBe(true);
    // login should now fail (account soft-deleted)
    await request(app.getHttpServer())
      .post('/api/auth/login').send({ email, password: 'password123' }).expect(401);
  });
});
