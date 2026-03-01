import { test, expect } from '@playwright/test';
import { ApiHelper } from '../../utils/ApiHelper';
import { TestData } from '../../utils/TestData';

test.describe('Auth API — Login & Registration', () => {
  let api: ApiHelper;

  test.beforeEach(async ({ request }) => { api = new ApiHelper(request); });

  test('valid login returns token',              { tag: ['@smoke', '@regression'] }, async () => {
    const res = await api.post('/api/login', TestData.api.validLogin);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('token');
    expect(body.token.length).toBeGreaterThan(0);
  });

  test('login without password returns 400',    { tag: ['@regression'] }, async () => {
    const res = await api.post('/api/login', { email: TestData.api.validLogin.email });
    expect(res.status()).toBe(400);
    expect((await res.json()).error).toBe('Missing password');
  });

  test('login with unregistered email returns 400', { tag: ['@regression'] }, async () => {
    const res = await api.post('/api/login', { email: 'notreal@test.com', password: 'x' });
    expect(res.status()).toBe(400);
  });

  test('register with valid payload returns id and token', { tag: ['@regression'] }, async () => {
    const res = await api.post('/api/register', TestData.api.validLogin);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('id');
    expect(body).toHaveProperty('token');
  });

  test('authenticated request with bearer token succeeds', { tag: ['@regression'] }, async ({ request }) => {
    const loginRes = await api.post('/api/login', TestData.api.validLogin);
    const { token } = await loginRes.json() as { token: string };
    const authApi = new ApiHelper(request, token);
    const res = await authApi.get('/api/users/2');
    expect(res.status()).toBe(200);
  });
});
