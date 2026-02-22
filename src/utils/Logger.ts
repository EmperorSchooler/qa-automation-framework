type LogLevel = 'INFO' | 'WARN' | 'ERROR' | 'DEBUG';

export class Logger {
  private readonly context: string;

  constructor(context: string) {
    this.context = context;
  }

  private format(level: LogLevel, msg: string): string {
    return `[${new Date().toISOString()}] [${level}] [${this.context}] ${msg}`;
  }

  info(msg: string):  void { console.log(this.format('INFO',  msg)); }
  warn(msg: string):  void { console.warn(this.format('WARN',  msg)); }
  error(msg: string, err?: Error): void {
    console.error(this.format('ERROR', msg));
    if (err?.stack) console.error(err.stack);
  }
  debug(msg: string): void {
    if (process.env.DEBUG === 'true') console.log(this.format('DEBUG', msg));
  }
}
