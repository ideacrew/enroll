import { Component, Injector, ElementRef, Inject, ViewChild, Input } from '@angular/core';
import { FormGroup, FormControl, AbstractControl, FormArray, FormBuilder, Validators } from '@angular/forms';
import { QuestionComponentRemover } from './question_component_remover';
import { QleKindResponseFormComponent } from './qle_kind_question_response_form.component';


@Component({
  selector: 'qle-question-form',
  templateUrl: './qle_kind_question_form.component.html'
})

export class QleKindQuestionFormComponent {
  public showResponseForm : boolean = false;

  @Input("questionFormGroup")
  public questionFormGroup : FormGroup | null;
  
  @Input("questionIndex")
  public questionIndex : number | null;
  
  @Input("questionComponentParent")
  public questionComponentParent : QuestionComponentRemover | null;

  @Input("responseArray")
  public responseArray : FormArray;
  
  constructor(private _questionForm: FormBuilder) {
    }

  ngOnInit() {
    // this.getResponseArray()
  }

//  public getResponseArray(){
//    return this.responseArray
//  }

  public responseControls() : FormGroup[] {
    return this.responseArray.controls.map(
      function(item) {
        return <FormGroup>item;
      }
    );
  }

  public removeQuestion() {
    if (this.questionComponentParent != null) {
      if (this.questionIndex != null) {
        this.questionComponentParent.removeQuestion(this.questionIndex);
      }
    }
  }

  public submitQuestion(){
    if (this.questionFormGroup != null){
        this.showResponseForm = true
        this.addResponse()
    }
  }


  public addResponse(){
    var responseForm = new QleKindResponseFormComponent()
    this.responseArray.push(
      responseForm.newResponseFormGroup()
    ); 
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }

  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

 public newQuestionFormGroup(formBuilder: FormBuilder) {
    var rControls = formBuilder.array([]);
    var questionForm = new FormGroup({
      id: new FormControl(""),
      question_title: new FormControl('', Validators.required),
      question_type: new FormControl(''),
      responses: rControls,
      correctAnswer: new FormControl('', Validators.required),
    });
    this.responseArray = rControls;
    return questionForm
  }

}
