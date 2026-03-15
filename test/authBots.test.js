const request = require('supertest');
const { buildApp } = require('../src/app.js');

const app = buildApp();

describe('Auth + Bots flow', () => {
  let token;

  it('registers a user', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ email: 'test@example.com', password: 'testpass' });
    expect(res.statusCode).toBe(201);
    expect(res.body.token).toBeDefined();
    token = res.body.token;
  });

  it('lists bots (empty for new user)', async () => {
    const res = await request(app)
      .get('/api/bots')
      .set('Authorization', 'Bearer ' + token);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });
});
