import { BaseHttpController, results } from "inversify-express-utils";

export class Controller extends BaseHttpController {
  resolveError(err: any): results.JsonResult {
    const errData = err.response ? err.response.data : { error: err.message };
    const statusCode = err.response ? err.response.status : err.httpCode || 500;
    return this.json(errData, statusCode);
  }
}
