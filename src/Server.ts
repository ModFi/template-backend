import { Application } from "./Application";
import { Server as HttpServer } from "http";
import { Environment } from "./Environment";
import { injectable } from "inversify";
import { log } from "@modfi/backend-utils";

@injectable()
export class Server {
  constructor(private app: Application, private env: Environment) {}

  up = (): HttpServer => {
    const port = this.env.serverPort;
    const expressApp = this.app.build();
    return expressApp.listen(port, () => {
      log.i(`Server running on port ${port}`);
    });
  };
}
