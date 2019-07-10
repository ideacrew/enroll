import { Component, Injector, ElementRef, Inject, ViewChild  } from '@angular/core';
import { QleKindCreationResource } from './qle_kind_creation_data';
import { FormGroup, FormControl, AbstractControl, FormArray, FormBuilder, Validators } from '@angular/forms';
import { QleKindCreationService } from '../qle_kind_services';
import { ErrorLocalizer } from '../../../error_localizer';
import { ErrorMapper, ErrorResponse } from '../../../error_mapper';
import { QleKindQuestionFormComponent } from './qle_kind_question_form.component';
import { __core_private_testing_placeholder__ } from '@angular/core/testing';


@Component({
  selector: 'admin-qle-kind-creation-form',
  templateUrl: './qle_kind_creation_form.component.html'
})
export class QleKindCreationFormComponent {
  public qleKindToCreate : QleKindCreationResource | null = null;
  public creationFormGroup : FormGroup = new FormGroup({});
  public creationUri : string | "";
  public showQuestionInputs : boolean | false;
  public showQuestionType : boolean | false;
  public showQuestionTitle : boolean | false;
  public showQuestionContainer : boolean | false;
  public showQuestionDateForm : boolean | false;
  public showBetweenOperator : boolean | false;
  public showBeforeOperator : boolean | false;
  public showAfterOperator : boolean | false;
  public questionCreated : boolean | false;
  public lastQuestion : boolean | false;
  public showQuestionMultipleChoiceForm : boolean | false;



  @ViewChild('headerRef') headerRef: ElementRef;

  constructor(
     injector: Injector,
     private _elementRef : ElementRef,
     private _creationForm: FormBuilder,


     @Inject("QleKindCreationService") private CreationService : QleKindCreationService,
     ) {

  }
  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  ngOnInit() {
    var qleKindToCreateJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-create-url");
        this.creationFormGroup = this._creationForm.group({
          title: ['', [Validators.required, Validators.minLength(1)]],
          tool_tip: ['', [Validators.required, Validators.minLength(1)]],
          action_kind: ['',[]],
          reason: ['', [Validators.required, Validators.minLength(1)]],
          market_kind: ['', [Validators.required, Validators.minLength(1)]],
          is_self_attested: [''],
          questions: this._creationForm.array([
          ]),
        })
      
    var submissionUriAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-creation-url");
      if (submissionUriAttribute != null) {
        this.creationUri = submissionUriAttribute;
      }
  }

  getresponseDateFirst(){
  }

  responseOperatorChosen(o:number){
  }

  initQuestion(){
   return  this._creationForm.group({
      id: "",
      questionTitle: ['', Validators.required],
      questionType:[''],
      responses: this._creationForm.array([
        this.initElement('responses')
      ]),
    });
  }

  checkOperator(questionIndex:number,responseIndex:number){
    const operator = this.creationFormGroup.value.questions[questionIndex].responses[responseIndex].responseDateOperator
    if (operator === "between"){
      this.showBetweenOperator = true
    }
    else if (operator === "before"){
      this.showBeforeOperator = true
    }    
    else if (operator === "after"){
      this.showAfterOperator = true
    }
  }

  initElement(elementName: string): FormGroup {
      if(elementName === 'questions') {
      return this._creationForm.group({
        id: "",
        questionTitle: ['', Validators.required],
        questionType:[''],
        responses: this._creationForm.array([
          this.initElement('responses')
        ])
      })
    } else if (elementName === 'responses') {
      return this._creationForm.group({
        id: "",
        responseBoolean: [false],
        responseMultipleChoice:[''],
        responseDateFirst:[''],
        responseDateLast:[''],
        responseDateOperator:[''],
      })
    }
    else {
      return this._creationForm.group({
      })
    };
  }


  addElement(formGroup: FormGroup, elementName: string): void {
    const control = < FormArray > formGroup.controls[elementName];
    control.push(this.initElement(elementName));
  }

  displayQuestionTitle(i:number){
    var title = this.creationFormGroup.value.questions[i].questionTitle;
    return title
  }

  initResponse(){
    const response = this._creationForm.group({
      id: "",
      responseBoolean: [false],
      responseMultipleChoice:[''],
      responseDateFirst:[''],
      responseDateLast:[''],
      responseDateOperator:[''],
    });
    return response
  }

  questionTypeSelected(type:string){
    this.showQuestionType = false
    if (type == "date"){
      this.showQuestionDateForm = true;
    }
    else if(type == "boolean"){
    }  
    else if(type == "multipleChoice"){
      this.showQuestionMultipleChoiceForm = true;

    }
  }

  showQuestionTypes(){
      this.showQuestionInputs = false
      this.showQuestionType = true
      this.showQuestionTitle = true
  }

  showQuestionInput(questionIndex:number){
    const questions = this.creationFormGroup.value.questions
    if (questions.length == 1 || questionIndex == (questions.length-1)){
      return true
    }
    else{
      return false
    }
  }

  showQuestions(){
    this.showQuestionContainer = true
    this.showQuestionInputs = true

  }

  submitQuestion(){
    this.showQuestionDateForm = false
    this.questionCreated = true 
    this.showQuestionTitle = false
    this.showQuestionInputs = false
    this.showBeforeOperator = false
    this.showAfterOperator = false
    this.showBetweenOperator = false

    console.log(this.creationFormGroup.value)
  }

  submitCreation() {
    var form = this;
    var errorMapper = new ErrorMapper();
    
    if (this.creationFormGroup != null) {
      if (this.creationFormGroup.valid) {
        // var invocation = this.CreationService.submitCreation(this.creationUri, this.creationFormGroup.value);
        // invocation.subscribe(
        //   function(data: HttpResponse<any>) {
        //     var location_header = data.headers.get("Location");
        //     if (location_header != null) {
        //       window.location.href = location_header;
        //     }
        //   },
        //   function(error) {
        //     errorMapper.mapParentErrors(form.creationFormGroup, <ErrorResponse>(error.error.errors));
        //     errorMapper.processErrors(form.creationFormGroup, <ErrorResponse>(error.error.errors));
        //     form.headerRef.nativeElement.scrollIntoView();
        //   }
        // )
      }
    }
  }
}


// import { FormGroup, FormArray, tslib, FormBuilder, Validators, FormControl, NgControl  } from '@angular/forms'
// import { Component, OnInit } from '@angular/core';

// @Component({
//   selector: 'admin-qle-kind-creation-form',
//   templateUrl: './qle_kind_creation_form.component.html'
// })
// export class QleKindCreationFormComponent {
        
//     proxyMedia: FormArray;
//     formGroup: FormGroup;
    
//     constructor(
//     public formBuilder: FormBuilder
//     ) {}
    
//     ngOnInit() {
//         this.formGroup = this.formBuilder.group({
//         test_name: ['', [Validators.required]],
//         tests: this.formBuilder.array([
//             this.initTestsForm()
//             ])
//         });
//     }
    
//     initTestsForm(): any {
//         return this.formBuilder.group({
//         test_num: '',
//         categorie: '',
//         responses: this.formBuilder.array([
//             this.initElement('responses')
//             ])
//         });
//     }
    
//     initElement(elementName: string): FormGroup {
//         if(elementName === 'proxy_media') {
//             return this.formBuilder.group(
//             {
//             prefixe: 'prefixe',
//             confid: 'confid'
//             }
//             );
//         } else if(elementName === 'tests') {
//             return this.formBuilder.group({
//             test_num: ['test_num', [Validators.required, Validators.minLength(2)]],
//             categorie: ['categorie', [Validators.required, Validators.minLength(2)]],
//             responses: this.formBuilder.array([
//                 this.initElement('responses')
//                 ])
//             });
//         } else if(elementName === 'responses') {
//             return this.formBuilder.group({
//             code_response: ['code_response', Validators.required],
//             log_level: ['log_level', Validators.required]
//             });
//         }
//     }
    
//     addElement(formGroup: FormGroup, elementName: string): void {
//         const control = < FormArray > formGroup.controls[elementName];
//         control.push(this.initElement(elementName));
//     }
    
//     removeElement(formGroup: FormGroup, elementName: string, index: number): void {
//         const control = <FormArray>formGroup.controls[elementName];
//         control.removeAt(index);
//     }
    
//     onSubmit(o: any) {
//         console.log(o);
//     }
    
//     debug(data: any) {
//         console.warn('debug: data ');
//         console.warn(data);
//         console.warn('stop');
//     }
    
// }