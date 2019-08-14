import { Component, Input } from '@angular/core';
import { FormGroup, FormControl, FormArray, AbstractControl, Validators } from '@angular/forms';
import { ResponseComponentRemover } from './response_component_remover';
import { QleKindQuestionFormComponent } from './qle_kind_question_form.component';

@Component({
  selector: 'qle-question-response-form',
  templateUrl: './qle_kind_question_response_form.component.html'
})

export class QleKindResponseFormComponent {
  public showAddAnotherResponse : boolean = false;

  @Input("responseFormGroup")
  public responseFormGroup : FormGroup | null;

  @Input("responseIndex")
  public responseIndex : number | null;

  @Input("responseComponentParent")
  public responseComponentParent : ResponseComponentRemover | null;

  constructor() {
  }

  ngOnInit(){

  }

  public showIndex() {
    return this.responseIndex;
  }

  public removeResponse(responseIndex: number) {
    if (this.responseComponentParent != null) {
      if (responseIndex != null) {
        this.responseComponentParent.removeResponse(responseIndex);
      }
    }
  }

  public addNewResponse(questionComponent: QleKindQuestionFormComponent, responseIndex: number){
    if (questionComponent != null) {
      if (questionComponent.questionFormGroup != null) {
        if (this.responseFormGroup != null) {
          questionComponent.questionFormGroup.value.responses[responseIndex] = this.responseFormGroup.value
   
        }     
      }     
      questionComponent.addResponse()
    }
  }

  public selectResponse(){
    if (this.responseFormGroup != null) {
      console.log(this.responseFormGroup.parent.value)
    }
  }

  public createResponse(){
    if(this.responseFormGroup != null){
      this.showAddAnotherResponse = true
    }
  }
  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  public static newResponseFormGroup() : FormGroup {
    var responseForm = new FormGroup({
      response_title: new FormControl('', Validators.required),
      response_accepted: new FormControl('false'),
      response_type: new FormControl('select'),
    });
    return responseForm;
  }


}
