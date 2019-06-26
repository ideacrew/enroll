import { Observable } from "rxjs";
import { HttpResponse } from "@angular/common/http";

export interface QleKindDeactivationService {
  submitDeactivate(post_uri: string, obj_data : object) : Observable<HttpResponse<any>>;
}

export interface QleKindUpdateService {
  submitUpdate(post_uri: string, obj_data : object) : Observable<HttpResponse<any>>;
}

export interface QleKindCreationService {
  submitCreate(post_uri: string, obj_data : object) : Observable<HttpResponse<any>>;
}