import { Component, Injector, ElementRef } from '@angular/core';
import { QleKindCreationResource } from './qle_kind_creation_data';
import { FormGroup, FormControl, AbstractControl, Validators } from '@angular/forms';

@Component({
  selector: 'admin-qle-kind-creation-form',
  templateUrl: './qle_kind_creation_form.component.html'
})
export class QleKindcreationFormComponent {
  public qleKindToCreate : QleKindCreationResource | null = null;
  public creationFormGroup : FormGroup | null = null;
  constructor(injector: Injector, private _elementRef : ElementRef) {

  }
  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }
  ngOnInit() {
    var qleKindToCreateJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-to-create");
    if (qleKindToCreateJson != null) {
      this.qleKindToCreate = JSON.parse(qleKindToCreateJson)
      if (this.qleKindToCreate != null) {
        this.creationFormGroup = new FormGroup({
          id: new FormControl(this.qleKindToCreate.id),
          end_on: new FormControl("")
        })
      }
    }
  }

  hasResource() {
    return this.qleKindToCreate != null;
  }

  submitcreation() {
    if (this.creationFormGroup != null) {
      if (this.creationFormGroup.valid) {
        console.log(this.creationFormGroup.value)
      }
    }
  }
}
