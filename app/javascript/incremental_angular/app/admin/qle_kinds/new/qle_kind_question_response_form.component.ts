import { Component, Input } from '@angular/core';
import { FormGroup, FormControl, FormArray, AbstractControl, Validators } from '@angular/forms';
import { ResponseComponentRemover } from './response_component_remover';

@Component({
  selector: 'qle-question-response-form',
  templateUrl: './qle_kind_question_response_form.component.html'
})

export class QleKindResponseFormComponent {
  // public responseArray : FormArray;

  @Input("responseFormGroup")
  public responseFormGroup : FormGroup | null;

  @Input("responseIndex")
  public responseIndex : number | null;

  @Input("responseComponentParent")
  public responseComponentParent : ResponseComponentRemover | null;

  constructor() {}

  public showIndex() {
    console.log(this.responseFormGroup);
    return this.responseIndex;
  }

  public removeResponse() {
    if (this.responseComponentParent != null) {
      if (this.responseIndex != null) {
        this.responseComponentParent.removeResponse(this.responseIndex);
      }
    }
  }

  public selectResponse(){
    if (this.responseFormGroup != null) {
      console.log(this.responseFormGroup.parent.value)
    }
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  static newResponseFormGroup(){
    return new FormGroup({
      id: new FormControl(""),
      response_title: new FormControl('', Validators.required),
      response_accepted: new FormControl('true'),
    });
  }


}
