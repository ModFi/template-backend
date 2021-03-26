import {
  BaseHttpController,
  controller,
  httpGet,
  interfaces,
  results,
} from "inversify-express-utils";

@controller("/v1/health")
export class HealthControllerV1
  extends BaseHttpController
  implements interfaces.Controller {
  @httpGet("/")
  health(): results.JsonResult {
    return this.json({ msg: "OK" });
  }
}
