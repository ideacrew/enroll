import { Component, Injector, ElementRef, Inject, ViewChild  } from '@angular/core';
import { QleKindCreationResource } from './qle_kind_creation_data';
import { FormGroup, FormControl, AbstractControl, FormArray, FormBuilder, Validators } from '@angular/forms';
import { QleKindCreationService } from '../qle_kind_services';
import { ErrorLocalizer } from '../../../error_localizer';
import { ErrorMapper, ErrorResponse } from '../../../error_mapper';
import { HttpResponse } from "@angular/common/http";
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
  public showQuestionInput : boolean | true;
  public showQuestionType : boolean | false;
  public showQuestionTitle : boolean | false;
  public showQuestionContainer : boolean | false;



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
        // this.creationFormGroup.addControl(
        //   "title",
        //   new FormControl(""),
        // )
        // this.creationFormGroup.addControl(
        //   "tool_tip",
        //   new FormControl(""), 
        // )
        // this.creationFormGroup.addControl(
        //   "action_kind",
        //   new FormControl(""),  
        // )
        // this.creationFormGroup.addControl(
        //   "reason",
        //   new FormControl(""),  
        // )
        // this.creationFormGroup.addControl(
        //   "market_kind",
        //   new FormControl(""),  
        // )
        // this.creationFormGroup.addControl(
        //   "is_self_attested",
        //   new FormControl(""),  
        // )
        this.creationFormGroup = this._creationForm.group({
          title: ['', [Validators.required, Validators.minLength(1)]],
          tool_tip: ['', [Validators.required, Validators.minLength(1)]],
          action_kind: ['',[]],
          reason: ['', [Validators.required, Validators.minLength(1)]],
          market_kind: ['', [Validators.required, Validators.minLength(1)]],
          is_self_attested: [''],
          questions: this._creationForm.array([
            this.initQuestion(),
          ])
        })
      
    var submissionUriAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-creation-url");
      if (submissionUriAttribute != null) {
        this.creationUri = submissionUriAttribute;
      }
  }

  initQuestion(){
    return this._creationForm.group({
      id: "",
      questionTitle: ['', Validators.required],
      questionType:[''],
    });

  }
  displayQuestionTitle(){
    var title =  this.creationFormGroup.value.questions[0].questionTitle;
    return title
  }

  showDateQuestionTypeForm(){

  }

  showMultipleChoiceQuestionTypeForm(){

  }

  showBooleanQuestionTypeForm(){

  }


  questionTypeSelected(type){
    this.showQuestionType = false
    if (type=="date"){
      this.showDateQuestionTypeForm()
    }
    else if(type=="boolean"){
      this.showBooleanQuestionTypeForm()
    }  
    else if(type=="multipleChoice"){
      this.showMultipleChoiceQuestionTypeForm()
    }
  }

  showQuestionTypes(){
           this.showQuestionInput = false
           this.showQuestionType = true
           this.showQuestionTitle = true


  }
  showQuestions(){
       this.showQuestionContainer = true
    return this.showQuestionInput = true

  }

  addQuestion(){
    const control = <FormArray>this.creationFormGroup.controls['questions'];
    control.push(this.initQuestion());
    console.log(control)
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
