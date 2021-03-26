import "reflect-metadata";
import container from "./container/inversify.config";
import {
  errorHandler,
  httpLoggingFormat,
  requestId,
} from "@modfi/backend-utils";
import bodyParser from "body-parser";
import compression from "compression";
import { Application as ExpressApplication, Request, Response } from "express";
import helmet from "helmet";
import { injectable } from "inversify";
import { InversifyExpressServer } from "inversify-express-utils";
import morgan from "morgan";
import "./http/controllers/v1/HealthControllerV1";
import * as OpenApiValidator from "express-openapi-validator";
import swaggerUi from "swagger-ui-express";
import { Environment } from "./Environment";
import path from "path";
import YAML from "yamljs";
import { log } from "@modfi/backend-utils";

@injectable()
export class Application {
  constructor(private env: Environment) {}
  build = (): ExpressApplication => {
    const inversifyExpressServer = new InversifyExpressServer(container, null, {
      rootPath: "/##SERVICE##",
    });
    inversifyExpressServer.setConfig((app: ExpressApplication) => {
      this.addMiddlewares(app);
      this.docsConfig(app).then((message) => log.i(message));
    });
    return inversifyExpressServer.build();
  };

  private addMiddlewares = (app: ExpressApplication): void => {
    app.use(helmet());
    app.use(errorHandler);
    app.use(requestId());
    app.use(compression());
    app.use(bodyParser.urlencoded({ extended: true }));
    app.use(morgan(httpLoggingFormat()));
  };

  private async docsConfig(app: ExpressApplication): Promise<string> {
    try {
      let loggerMessage = "";
      const spec: string = path.join(
        process.cwd(),
        `./docs/api/v1/assets/openapi.yaml`
      );
      log.i(spec);
      if (this.env.get("API_DOCS_ENABLED") === "true") {
        const swaggerDocument = YAML.load(spec);

        app.use(
          `/##SERVICE##/v1/api-docs`,
          swaggerUi.serve,
          swaggerUi.setup(swaggerDocument)
        );

        log.d(`OpenApi Spec::Tool::added::/##SERVICE##/v1/api-docs`);
        loggerMessage = "Swagger docs enabled";
      } else {
        loggerMessage = "Swagger docs disabled";
        app.use(`/##SERVICE##/v1/api-docs`, (req: Request, res: Response) => {
          res.json({ msg: loggerMessage });
        });
      }
      app.use(
        OpenApiValidator.middleware({
          apiSpec: spec,
          validateRequests: false,
          validateResponses: false,
          validateSecurity: false,
        })
      );

      log.d(`OpenApiValidator::Added::${spec}`);
      return loggerMessage;
    } catch (err) {
      log.e(err);
      return err.message;
    }
  }
}
