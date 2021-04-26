import * as dotenv from "dotenv";
import { getEnv } from "@modfi/backend-utils";
import { injectable } from "inversify";

@injectable()
export class Environment {
  private readonly qualifier: string | undefined;
  private static instance: Environment;
  private constructor() {
    this.qualifier = process.env.NODE_ENV;
    switch (this.qualifier) {
      case "test":
        dotenv.config({ path: `${process.cwd()}/.env.test` });
        break;
      case "development":
        dotenv.config({ path: `${process.cwd()}/.env.development` });
        break;
      default:
        return;
    }
  }

  static getInstance = (): Environment => {
    if (!Environment.instance) {
      Environment.instance = new Environment();
    }
    return Environment.instance;
  };

  get serverPort(): number {
    return parseInt(getEnv("SERVER_PORT", "3000"));
  }

  get dbUrl(): string {
    return getEnv("DB_API_URL");
  }

  get dbToken(): string {
    return getEnv("DB_API_TOKEN");
  }

  isProduction(): boolean {
    return this.qualifier === "production";
  }

  get(key: string): string {
    return getEnv(key);
  }

  get apiDocs(): string {
    return getEnv("API_DOCS_ENABLED", "false");
  }

  isTest(): boolean {
    return this.qualifier === "test";
  }
}
