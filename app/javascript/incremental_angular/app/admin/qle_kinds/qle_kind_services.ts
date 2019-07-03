import { Observable } from "rxjs";
import { HttpResponse } from "@angular/common/http";

export interface QleKindDeactivationService {
  submitDeactivate(post_uri: string, obj_data : object) : Observable<HttpResponse<any>>;
}

export interface QleKindCreationService {
  submitCreation(post_uri: string, obj_data : object) : Observable<HttpResponse<any>>;
}