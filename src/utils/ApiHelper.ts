import { APIRequestContext, APIResponse } from '@playwright/test';
import { Logger } from './Logger';

export class ApiHelper {
  private readonly request: APIRequestContext;
  private readonly token: string | null;
  private readonly logger: Logger;

  constructor(request: APIRequestContext, token: string | null = null) {
    this.request = request;
    this.token   = token;
    this.logger  = new Logger('ApiHelper');
  }

  private buildHeaders(extra: Record<string, string> = {}): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...extra,
    };
    if (this.token) headers['Authorization'] = `Bearer ${this.token}`;
    return headers;
  }

  async get(endpoint: string): Promise<APIResponse> {
    this.logger.info(`GET ${endpoint}`);
    const res = await this.request.get(endpoint, { headers: this.buildHeaders() });
    this.logger.info(`← ${res.status()} ${endpoint}`);
    return res;
  }

  async post(endpoint: string, body: object): Promise<APIResponse> {
    this.logger.info(`POST ${endpoint} body=${JSON.stringify(body)}`);
    const res = await this.request.post(endpoint, { headers: this.buildHeaders(), data: body });
    this.logger.info(`← ${res.status()} ${endpoint}`);
    return res;
  }

  async put(endpoint: string, body: object): Promise<APIResponse> {
    this.logger.info(`PUT ${endpoint}`);
    const res = await this.request.put(endpoint, { headers: this.buildHeaders(), data: body });
    this.logger.info(`← ${res.status()} ${endpoint}`);
    return res;
  }

  async patch(endpoint: string, body: object): Promise<APIResponse> {
    this.logger.info(`PATCH ${endpoint}`);
    const res = await this.request.patch(endpoint, { headers: this.buildHeaders(), data: body });
    this.logger.info(`← ${res.status()} ${endpoint}`);
    return res;
  }

  async delete(endpoint: string): Promise<APIResponse> {
    this.logger.info(`DELETE ${endpoint}`);
    const res = await this.request.delete(endpoint, { headers: this.buildHeaders() });
    this.logger.info(`← ${res.status()} ${endpoint}`);
    return res;
  }

  async assertStatus(response: APIResponse, expected: number): Promise<void> {
    if (response.status() !== expected) {
      const body = await response.text().catch(() => '<unreadable>');
      throw new Error(`Expected HTTP ${expected}, got ${response.status()}.\nBody: ${body}`);
    }
  }
}
