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

  public responseControls(){
    if (this.questionFormGroup != null && this.questionFormGroup.value != null) {
      return this.questionFormGroup.value.responses.map(
        function(item:FormGroup) {
          return <FormGroup>item;
        }
      );
    }
  }

  public removeQuestion() {
    if (this.questionComponentParent != null) {
      if (this.questionIndex != null) {
        this.questionComponentParent.removeQuestion(this.questionIndex);
      }
    }
  }

  public startQuestion(){
    if (this.questionFormGroup != null){
        this.showResponseForm = true
        this.addResponse()
    }
  }

    public submitQuestion(){
    if (this.questionFormGroup != null){
        this.showResponseForm = true
        console.log(this.questionFormGroup.value)
    }
  }


  removeResponse(responseIndex: number) {
    if(this.questionFormGroup != null && this.questionFormGroup.value.responses != null) {
      this.questionFormGroup.value.responses.splice(responseIndex,1);
        console.log(this.questionFormGroup.value.responses)

    }
  }

  public addResponse(){
    if (this.questionFormGroup != null) {
    const control:FormArray = this.questionFormGroup.get('responses') as FormArray;  
      if (control){
        var responseForm = new QleKindResponseFormComponent()
        control.push(
          responseForm.newResponseFormGroup()
        ); 
      }
    }
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }

  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  // public responseArray : FormArray;
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
    this.questionFormGroup = questionForm;
    return questionForm
  }

}
