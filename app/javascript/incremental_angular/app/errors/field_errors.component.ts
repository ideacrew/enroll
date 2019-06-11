import { Component, Input } from '@angular/core';
import { AbstractControl, ValidationErrors } from '@angular/forms';
import { ErrorLocalizer } from '../error_localizer';

@Component({
  selector: 'field-errors',
  templateUrl: './field_errors.component.html'
})
export class FieldErrorsComponent {
  @Input("errorControl")
  public errorControl: AbstractControl;

  @Input("errorHeader")
  public errorHeader: string;

  constructor(private errorLocalizer : ErrorLocalizer) {
  }

  public errorsFor(control : AbstractControl) : string[] {
    var v = control.errors;
    var localizer = this.errorLocalizer;
    if (v != null) {
      var ks = Object.keys(<ValidationErrors>v);
      var errs : Array<string> = [];
      ks.forEach(function(k) {
          let e = v![k];
          if (k.startsWith("server_validation_")) {
            if (e != null) {
              errs.push(<string>e);
            }
          } else {
            errs.push(localizer.translate(<string>k));
          }
      });
      return errs;
    }
    return [];
  }

  public hasErrorHeader() {
    return this.errorHeader != null;
  }

  public hasErrorMessages(control : AbstractControl) : Boolean {
    var invalid = ((control.touched || control.dirty) && !control.valid);
    if (invalid) {
    var v = control.errors;
    if (v != null) {
      var ks = Object.keys(<ValidationErrors>v);
      return ks.length > 0;
    }
    }
    return false;
  }
}