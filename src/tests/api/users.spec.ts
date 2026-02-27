import { test, expect } from '@playwright/test';
import { ApiHelper } from '../../utils/ApiHelper';
import { TestData } from '../../utils/TestData';

test.describe('Users API — Full CRUD', () => {
  let api: ApiHelper;

  test.beforeEach(async ({ request }) => { api = new ApiHelper(request); });

  test('GET /users returns paginated list',     { tag: ['@smoke', '@regression'] }, async () => {
    const res = await api.get('/api/users?page=1');
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.length).toBeGreaterThan(0);
  });

  test('GET /users/:id returns correct user',  { tag: ['@smoke', '@regression'] }, async () => {
    const res = await api.get('/api/users/2');
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.data.id).toBe(2);
    expect(body.data).toHaveProperty('email');
  });

  test('GET /users/:id returns 404 for unknown user', { tag: ['@regression'] }, async () => {
    const res = await api.get('/api/users/9999');
    expect(res.status()).toBe(404);
  });

  test('POST /users creates user with 201',    { tag: ['@smoke', '@regression'] }, async () => {
    const res = await api.post('/api/users', TestData.api.newUser);
    expect(res.status()).toBe(201);
    const body = await res.json();
    expect(body.name).toBe(TestData.api.newUser.name);
    expect(body).toHaveProperty('id');
    expect(body).toHaveProperty('createdAt');
  });

  test('PUT /users/:id fully replaces user',   { tag: ['@regression'] }, async () => {
    const res = await api.put('/api/users/2', TestData.api.updatedUser);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.job).toBe(TestData.api.updatedUser.job);
    expect(body).toHaveProperty('updatedAt');
  });

  test('PATCH /users/:id partial update',      { tag: ['@regression'] }, async () => {
    const res = await api.patch('/api/users/2', { job: 'QA Lead' });
    expect(res.status()).toBe(200);
    expect((await res.json()).job).toBe('QA Lead');
  });

  test('DELETE /users/:id returns 204',        { tag: ['@regression'] }, async () => {
    const res = await api.delete('/api/users/2');
    expect(res.status()).toBe(204);
  });
});
