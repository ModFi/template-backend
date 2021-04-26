import { Environment } from "../../Environment";
import { cognitoJWTVerifier } from "@modfi/backend-utils";
import { injectable } from "inversify";
import { BaseMiddleware } from "inversify-express-utils";
import { NextFunction, Request, RequestHandler, Response } from "express";
import { v4 as uuidv4 } from "uuid";

@injectable()
export class Auth extends BaseMiddleware {
  constructor(private env: Environment) {
    super();
  }

  handler = this.resolveHandler();

  private resolveHandler(): RequestHandler {
    return this.env.isTest() ? this.testingVerifier() : this.cognitoVerifier();
  }

  private cognitoVerifier(): RequestHandler {
    return cognitoJWTVerifier({
      poolId: this.env.get("COGNITO_POOL_ID"),
      region: this.env.get("COGNITO_REGION"),
    });
  }

  private testingVerifier(): RequestHandler {
    return (req: Request, res: Response, next: NextFunction) => {
      req.token = { sub: uuidv4() };
      next();
    };
  }
}
