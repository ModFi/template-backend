import { BaseMiddleware } from "inversify-express-utils";
import { NextFunction, Request, Response } from "express";

export class Uuid extends BaseMiddleware {
  handler = (req: Request, res: Response, next: NextFunction): void => {
    const uid = req.token.sub;
    if (!uid) {
      res.sendStatus(401);
      return;
    }
    req.cognitoId = uid;
    next();
  };
}
