import { Component, Injector, ElementRef, Inject, ViewChild } from '@angular/core';
import { QleKindEditResource } from './qle_kind_edit_data';
import { FormGroup, FormControl, FormBuilder, FormArray, AbstractControl, Validators } from '@angular/forms';
import { QleKindQuestionFormComponent } from '../new/qle_kind_question_form.component';
import { QleKindEditService } from '../qle_kind_services';
import { ErrorLocalizer } from '../../../error_localizer';
import { ErrorMapper, ErrorResponse } from '../../../error_mapper';
import { HttpResponse } from "@angular/common/http";
// import { DragDropModule } from '@angular/cdk/drag-drop';
// import {CdkDragDrop, moveItemInArray} from '@angular/cdk/drag-drop';

@Component({
  selector: 'admin-qle-kind-edit-form',
  templateUrl: './qle_kind_edit_form.component.html'
})
export class QleKindEditFormComponent {
  public qleKindToEdit : QleKindEditResource | null = null;
  public questionArray : FormArray;
  public editUri : string | null = null;
  public editFormGroup : FormGroup = new FormGroup({});
  @ViewChild('headerRef') headerRef: ElementRef;
  public marketKindsList = new FormArray([])
  
  public stringifiedStartOn = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-to-edit-end-on-stringified");
  public stringifiedEndOn = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-to-edit-end-on-stringified");

  public effectiveOnOptionsArray =  [
    {name: 'Date of Event', code: 'date_of_event'},
    {name: 'First of Next Month', code: 'first_of_next_month'},
    {name: 'First of Month', code: 'first_of_month'},
    {name: 'First Fixed of Next Month', code: 'fixed_first_of_next_month'},
    {name: 'Next 15 of the month', selected: false, id: 5},
    {name: 'Exact Date', code: 'exact_date', selected: false, id: 6},
    {name: 'Date options available', selected: false, id: 7}
  ]

  public actionKindList = [
    {name:"Not Applicable", code: "not_applicable"},
    {name:"Drop Member", code: "drop_member" }, 
    {name:"Adminstrative", code: "administrative" }, 
    {name:"Add Member", code: "add_member"},
    {name:"Add Benefit", code: "add_benefit" }, 
    {name:"Change Benefit", code: "change_benefit" }, 
    {name:"Transition Member", code: "transition_member"},
    {name:"Terminate Benefit", code: "terminate_benefit"}
  ]
  
  public reasonList = [
    {name:"Not Applicable", code: "not_applicable"},
    {name:"Natural Disaster", code: "exceptional_circumstances_natural_disaster"},
    {name:"Medical Emergency", code: "exceptional_circumstances_medical_emergency"},
    {name:"System Outage", code: "exceptional_circumstances_system_outage"},
    {name:"Domestic Abuse", code: "exceptional_circumstances_domestic_abuse"},
    {name:"Civic Service", code: "exceptional_circumstances_civic_service"},
    {name:"Exceptional Circumstances", code: "exceptional_circumstances"}  
  ]
  constructor(
    injector: Injector,
    @Inject("QleKindEditService") private editService : QleKindEditService,
    private errorLocalizer: ErrorLocalizer,
    private _editForm: FormBuilder,
    private _elementRef : ElementRef) {
     this.buildInitialForm(_editForm);

  }
  public getOptions(){
    return this.effectiveOnOptionsArray
  }
  private buildInitialForm(formBuilder : FormBuilder) {
    // var qControls = formBuilder.array([]);
    var submissionUriAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-edit-url");
    if (submissionUriAttribute != null) {
      this.editUri = submissionUriAttribute;
    }
    var marketKindsAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-market-kinds");
    if (marketKindsAttribute != null) {
      var marketKindsArrayJson = JSON.parse(marketKindsAttribute)
      this.marketKindsList = marketKindsArrayJson;
    }
    var qleKindToEditJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-to-edit");
    if (qleKindToEditJson != null) {
      this.qleKindToEdit = JSON.parse(qleKindToEditJson)
      if (this.qleKindToEdit != null){
        var formGroup = formBuilder.group({
          id: this.qleKindToEdit._id,
          title: ['', Validators.required],
          tool_tip: ['', [Validators.required, Validators.minLength(1)]],
          action_kind: ['',[]],
          reason: ['', [Validators.required, Validators.minLength(1)]],
          market_kind: [''],
          visible_to_customer: [''],
          custom_qle_questions: formBuilder.array([]),  
          is_self_attested: [''],
          effective_on_kinds:  new FormArray([]),
          pre_event_sep_in_days:[0, Validators.required],
          post_event_sep_in_days:[0, Validators.required],
          start_on: [''],   
          end_on: ['']
        })
        this.editFormGroup = formGroup;
        this.addCheckboxes();
      }
    }
  }
  private addCheckboxes() {
    this.effectiveOnOptionsArray.map((o, i) => {
      const control = new FormControl( i === 0); // if first item set to true, else false
      (this.editFormGroup.controls.effective_on_kinds as FormArray).push(control);
    });
  }


  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }

  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  hasResource() {
    // return this.qleKindToEdit != null;
  }

  // addQuestion() {
  //    this.questionArray.push(
  //      QleKindQuestionFormComponent.newQuestionFormGroup(this._editForm)
  //    );
  // }

  // removeQuestion(questionIndex: number) {
  //   this.questionArray.removeAt(questionIndex);
  // }

  // showQuestions(){
  //  return this.questionArray.length > 0;
  // }

  showQuestions(){
    // return this.qleKindToEdit.custom_qle_questionlength > 0;
    if(this.qleKindToEdit != null){
      return this.qleKindToEdit.custom_qle_questions.length > 0 
    }
  }

  public questionControls(): any {
    if(this.qleKindToEdit != null){
      if(this.qleKindToEdit.custom_qle_questions.length > 0 ){
       return this.qleKindToEdit.custom_qle_questions.map(
          function(item) {  
           return QleKindQuestionFormComponent.editQuestionFormGroup(item)
          }
        );
      }
    } 
  }

  submitEdit() {
    var form = this;
    var errorMapper = new ErrorMapper();
    if (this.editFormGroup != null) {
      if (this.editUri != null) {
        var invocation = this.editService.submitEdit(this.editUri, this.editFormGroup.value);
        invocation.subscribe(
          function(data: HttpResponse<any>) {
            var location_header = data.body.next_url;
            if (location_header != null) {
              // TODO: Can we add a div append here to show the success or decline message
              // or should we add a new function?
              window.location.href = location_header;
            }
          },
          function(error) {
            errorMapper.mapParentErrors(form.editFormGroup, <ErrorResponse>(error.error.errors));
            errorMapper.processErrors(form.editFormGroup, <ErrorResponse>(error.error.errors));
            form.headerRef.nativeElement.scrollIntoView();
          }
        )
      }
    } else {
        errorMapper.cascadeTouch(this.editFormGroup);
        errorMapper.invalidParentForm(this.editFormGroup);
    }
  }

  addQuestion() {
    this.questionArray.push(
      QleKindQuestionFormComponent.newQuestionFormGroup(this._editForm)
    );
  }
  
}
