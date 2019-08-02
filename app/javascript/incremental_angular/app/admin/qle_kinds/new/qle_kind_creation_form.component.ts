import { Component, Injector, ElementRef, Inject, ViewChild  } from '@angular/core';
import { QleKindCreationResource } from './qle_kind_creation_data';
import { FormGroup, FormControl, AbstractControl, FormArray, FormBuilder, Validators } from '@angular/forms';
import { QleKindCreationService } from '../qle_kind_services';
import { ErrorLocalizer } from '../../../error_localizer';
import { ErrorMapper, ErrorResponse } from '../../../error_mapper';
import { QleKindQuestionFormComponent } from './qle_kind_question_form.component';
import { __core_private_testing_placeholder__ } from '@angular/core/testing';
import { HttpResponse } from "@angular/common/http";



@Component({
  selector: 'admin-qle-kind-creation-form',
  templateUrl: './qle_kind_creation_form.component.html'
})
export class QleKindCreationFormComponent {
  public qleKindToCreate : QleKindCreationResource | null = null;
  public creationFormGroup : FormGroup;
  public questionArray : FormArray;
  public creationUri :  string | null = null;
  public marketKindsList : Array<string> | null = null;
  public questionCreated : boolean = false;
  public lastQuestion : boolean = false;
  public showQuestionMultipleChoiceForm : boolean = false;
  public effectiveOnOptionsArray =  [
      { name: 'Date of Event',  selected: false, id: 1 },
      { name: 'First of Next Month',  selected: false, id: 2 },
      { name: 'First of Month',  selected: false, id: 3 },
      { name: 'First Fixed of Next Month',  selected: false, id: 4 },
      { name: 'Next 15 of the month',  selected: false, id: 5 },
      { name: 'Exact Date',  selected: false, id: 6 },
      { name: 'Date options available',  selected: false, id: 7 }
    ]
  public actionKindList = [
      {name:"Not Applicable"},
      {name:"Drop Member"}, 
      {name:"Adminstrative"}, 
      {name:"Add Member"},
      {name:"Add Benefit"}, 
      {name:"Change Benefit"}, 
      {name:"Transition Member"}
  ]
  
  public reasonList = [
    "exceptional_circumstances_natural_disaster",
    "exceptional_circumstances_medical_emergency",
    "exceptional_circumstances_system_outage",
    "exceptional_circumstances_domestic_abuse",
    "exceptional_circumstances_civic_service",
    "exceptional_circumstances",
]
    @ViewChild('headerRef') headerRef: ElementRef;


  constructor(
     injector: Injector,
     private _elementRef : ElementRef,
     private _creationForm: FormBuilder,
     @Inject("QleKindCreationService") private CreationService : QleKindCreationService,
     ) {
     this.buildInitialForm(_creationForm);
  }

  private buildInitialForm(formBuilder : FormBuilder) {
    var qControls = formBuilder.array([]);

    var formGroup = formBuilder.group({
      title: ['', Validators.required],
      tool_tip: ['', [Validators.required, Validators.minLength(1)]],
      action_kind: ['',Validators.required],
      reason: ['', [Validators.required, Validators.minLength(1)]],
      market_kind: ['', [Validators.required, Validators.minLength(1)]],
      is_self_attested: [''],
      effective_on_kinds:  new FormArray([]),
      questions: qControls,
      pre_event_sep_in_days:[0, Validators.required],
      post_event_sep_in_days:[0, Validators.required],
      start_on: [''],   
      end_on: ['']
    });
    this.creationFormGroup = formGroup;

    this.questionArray = qControls;
    this.addCheckboxes();
  }

  private addCheckboxes() {
    this.effectiveOnOptionsArray.map((o, i) => {
      const control = new FormControl( i === 0); // if first item set to true, else false
      (this.creationFormGroup.controls.effective_on_kinds as FormArray).push(control);
    });
  }

  public getOptions(){
    const options = this.effectiveOnOptionsArray
    return options
  }
  public questionControls() : FormGroup[] {
    return this.questionArray.controls.map(
      function(item) {
        return <FormGroup>item;
      }
    );
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  ngOnInit() {

  // $( document ).ready(function() {
  //    $('select#qle_kind_creation_form_action_kind').selectric('destroy')
  // });

    var submissionUriAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-create-url");
    if (submissionUriAttribute != null) {
      this.creationUri = submissionUriAttribute;
    }
    var marketKindsAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-market-kinds");
    if (marketKindsAttribute != null) {
      var marketKindsArrayJson = JSON.parse(marketKindsAttribute)
      this.marketKindsList = marketKindsArrayJson;
    }
  }

  addQuestion() {
    this.questionArray.push(
      QleKindQuestionFormComponent.newQuestionFormGroup(this._creationForm)
    );
  }

  removeQuestion(questionIndex: number) {
    this.questionArray.removeAt(questionIndex);
  }

  showQuestions(){
    return this.questionArray.length > 0;
  }

  submitCreation() {
    var form = this;
    var errorMapper = new ErrorMapper();
    if (this.creationFormGroup != null) {
      this.creationFormGroup.value.action_kind =  this._elementRef.nativeElement.querySelector('select option:checked').value
      if (this.creationUri != null) {
        var invocation = this.CreationService.submitCreate(this.creationUri, this.creationFormGroup.value);
        invocation.subscribe(
          function(data: HttpResponse<any>) {
            var location_header = data.body.next_url;
            if (location_header != null) {
              window.location.href = location_header;
            }
          },
        )
      }
    }
  }
}
