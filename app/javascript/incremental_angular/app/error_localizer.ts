// We will later replace this with a service which requests the localized
// errors from the server.  For now, it returns constants.
export class ErrorLocalizer {
  private localizationMap : Map<string, string>;
  
  constructor () {
    this.localizationMap = new Map<string, string>();
    this.localizationMap.set("required", "must be provided");
    this.localizationMap.set("Mask error", "has an invalid format");
  }

  public translate(key: string) : string {
    var foundVal = this.localizationMap.get(key);
     if (foundVal != null && foundVal != undefined) {
       return foundVal;
     }
     return key;
  }
}