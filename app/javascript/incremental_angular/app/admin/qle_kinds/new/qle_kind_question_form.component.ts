import { Component, Input } from '@angular/core';
import { FormGroup, FormControl, FormArray, AbstractControl, Validators } from '@angular/forms';
import { QuestionComponentRemover } from './question_component_remover';

@Component({
  selector: 'qle-question-form',
  templateUrl: './qle_kind_question_form.component.html'
})
export class QleKindQuestionFormComponent {
  @Input("questionFormGroup")
  public questionFormGroup : FormGroup | null;

  @Input("questionIndex")
  public questionIndex : number | null;

  @Input("questionComponentParent")
  public questionComponentParent : QuestionComponentRemover | null;

  constructor() {}

  public showIndex() {
    console.log(this.questionFormGroup);
    return this.questionIndex;
  }

  public removeQuestion() {
    if (this.questionComponentParent != null) {
      if (this.questionIndex != null) {
        this.questionComponentParent.removeQuestion(this.questionIndex);
      }
    }
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  static newQuestionFormGroup() {
    return  new FormGroup({
      id: new FormControl(""),
      question_title: new FormControl('', Validators.required),
      question_type: new FormControl(''),
      responses: new FormArray([])
    });
  }
}
