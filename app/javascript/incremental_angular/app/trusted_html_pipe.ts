import { Pipe } from "@angular/core"
import { DomSanitizer } from "@angular/platform-browser"

@Pipe({name: 'trustedHtml'})
export class TrustedHtmlPipe {
  constructor(private sanitizer:DomSanitizer){}

  transform(value: any, args?: any): any {
    return this.sanitizer.bypassSecurityTrustHtml(value);
  }
}