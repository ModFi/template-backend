import { Container } from "inversify";
import { Server } from "../Server";
import { Application } from "../Application";
import { Environment } from "../Environment";
import { HealthControllerV1 } from "../http/controllers/v1/HealthControllerV1";

const container = new Container();

container.bind<Server>(Server).toSelf();
container.bind<Application>(Application).toSelf();
container
  .bind<Environment>(Environment)
  .toConstantValue(Environment.getInstance());
// Controllers
container.bind<HealthControllerV1>(HealthControllerV1).toSelf();

export default container;
