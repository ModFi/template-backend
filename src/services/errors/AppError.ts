export class AppError extends Error {
  constructor(public message: string, public httpCode: number = 500) {
    super(message);
  }
}
