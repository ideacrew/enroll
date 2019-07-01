import { Component, Injector, ElementRef } from '@angular/core';
import { QleKindDeactivationResource } from './qle_kind_deactivation_data';
import { FormGroup, FormControl, AbstractControl, Validators } from '@angular/forms';

@Component({
  selector: 'admin-qle-kind-deactivation-form',
  templateUrl: './qle_kind_deactivation_form.component.html'
})
export class QleKindDeactivationFormComponent {
  public qleKindToDeactivate : QleKindDeactivationResource | null = null;
  public deactivationFormGroup : FormGroup | null = null;
  constructor(injector: Injector, private _elementRef : ElementRef) {

  }
  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }
  ngOnInit() {
    var qleKindToDeactivateJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-to-deactivate");
    if (qleKindToDeactivateJson != null) {
      this.qleKindToDeactivate = JSON.parse(qleKindToDeactivateJson)
      if (this.qleKindToDeactivate != null) {
        this.deactivationFormGroup = new FormGroup({
          id: new FormControl(this.qleKindToDeactivate.id),
          end_on: new FormControl("")
        })
      }
    }
  }

  hasResource() {
    return this.qleKindToDeactivate != null;
  }

  submitDeactivation() {
    if (this.deactivationFormGroup != null) {
      if (this.deactivationFormGroup.valid) {
        console.log(this.deactivationFormGroup.value)
      }
    }
  }
}
