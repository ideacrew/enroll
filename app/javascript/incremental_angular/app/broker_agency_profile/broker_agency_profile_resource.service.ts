import { Injectable, ClassProvider } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable()
export class BrokerAgencyProfileResourceService {
  constructor(private http: HttpClient) { }

  public submitCreate(post_uri: string, obj_data : object) {
    var json = JSON.stringify({ data: obj_data });
    return this.http.post(
      post_uri + ".json",
      json,
      {
        withCredentials: true
      }
    )
  }

  static provides(token: string) : ClassProvider {
    return {provide: token, useClass: BrokerAgencyProfileResourceService}
  }
}