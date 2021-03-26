import container from "./container/inversify.config";
import { Server } from "./Server";
import { log } from "@modfi/backend-utils";

log.i("ENV: " + process.env.NODE_ENV);

const server = container.get<Server>(Server);

const httpServer = server.up();

["SIGINT", "SIGTERM", "SIGQUIT"].forEach((signature) => {
  process.on(signature, () => {
    httpServer.close((err) => {
      if (err) {
        log.e(err);
        return;
      }
      log.i(`${signature}: Gracefuly shutting down server.`);
    });
  });
});
