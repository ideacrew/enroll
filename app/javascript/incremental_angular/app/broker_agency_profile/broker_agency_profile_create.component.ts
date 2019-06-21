import { Component, Injector, ElementRef, ViewChild, Inject } from '@angular/core';
import { FormGroup, FormControl, Validators, AbstractControl, FormArray, ValidationErrors } from '@angular/forms';
import { LanguageList } from '../language_list';
import { PracticeAreaList } from  './practice_area_list';
import { BrokerAgencyProfileCreationService } from "./broker_agency_profile_services"
import { ErrorMapper, ErrorResponse } from '../error_mapper';

@Component({
  selector: 'broker-agency-profile-create',
  templateUrl: './broker_agency_profile_create.component.html'
})
export class BrokerAgencyProfileCreateComponent {
  profileForm : FormGroup;
  languageList: LanguageList = [];
  practiceAreaList: PracticeAreaList = [];
  stateList : String[] = [];
  brokerAgreementMessage : String = "";
  submitUri : string = "";
  submissionComplete : Boolean = false;
  submissionMessage : string = "";

  @ViewChild('headerRef') headerRef: ElementRef;

  constructor(injector: Injector, @Inject('BrokerAgencyProfileCreationService') private broker_api_service: BrokerAgencyProfileCreationService, private _elementRef : ElementRef) {
    this.profileForm = new FormGroup({
      first_name: new FormControl(null, Validators.required),
      last_name: new FormControl(null, Validators.required),
      email: new FormControl(null, Validators.required),
      npn: new FormControl(null, Validators.required),
      dob: new FormControl(null, Validators.required),
      legal_name: new FormControl(null, Validators.required),
      dba: new FormControl(null),
      practice_area: new FormControl('', Validators.required),
      languages: new FormControl(["en"]),
      evening_weekend_hours: new FormControl(false),
      accepts_new_clients: new FormControl(false),
      address: new FormGroup({
        address_1: new FormControl('', Validators.required),
        address_2: new FormControl(''),
        city: new FormControl('', Validators.required),
        state: new FormControl('SELECT STATE'),
        zip: new FormControl('', Validators.required)
      }),
      office_locations: new FormArray([])
    });
  }

  officeLocations() {
    return this.profileForm.get('office_locations') as FormArray;
  }
  
  ngOnInit() {
    var brokerAgreementJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-broker-registration-text");
    if (brokerAgreementJson != null) {
      this.brokerAgreementMessage = JSON.parse(brokerAgreementJson);
    }
    var practiceAreaJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-practice-area-list");
    if  (practiceAreaJson != null) {
      this.practiceAreaList = JSON.parse(practiceAreaJson);
    }
    var languageJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-language-list");
    if (languageJson != null) {
      this.languageList = JSON.parse(languageJson);
    }
    var stateJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-state-list");
    if (stateJson != null) {
      this.stateList = JSON.parse(stateJson);
    }
    var submitUriJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-submit-uri");
    if (submitUriJson != null) {
      this.submitUri = JSON.parse(submitUriJson);
    }
  }

  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  public errorsFor(control : AbstractControl) : string[] {
    var v = control.errors;
    if (v != null) {
      var ks = Object.keys(<ValidationErrors>v);
      var errs : Array<string> = [];
      ks.forEach(function(k) {
          let e = v![k];
          if (e != null) {
            errs.push(<string>e);
          }
      });
      return errs;
    }
    return [];
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }

  removeOfficeLocation(index: number) {
    this.officeLocations().removeAt(index);
  }

  addOfficeLocation() {
    var ol = this.createOfficeLocation();
   this.officeLocations().push(ol);
  }

  createOfficeLocation() : FormGroup {
    var new_group = new FormGroup({});
    return new_group;
  }

  public submitForm() {
    var invocation = this.broker_api_service.submitCreate(this.submitUri, this.profileForm.value);
    var form = this;
    var errorMapper = new ErrorMapper();
    if (this.profileForm.valid) {
    invocation.subscribe(
      function(data:  object) {
        form.submissionMessage = (<any>data).message;
        form.submissionComplete = true;
        form.headerRef.nativeElement.scrollIntoView();
      },
      function(error) {
        errorMapper.mapParentErrors(form.profileForm, <ErrorResponse>(error.error.errors));
        errorMapper.processErrors(form.profileForm, <ErrorResponse>(error.error.errors));
        form.headerRef.nativeElement.scrollIntoView();
      }
    )
    } else {
      errorMapper.cascadeTouch(this.profileForm);
      errorMapper.invalidParentForm(this.profileForm);
      form.headerRef.nativeElement.scrollIntoView();
    }
  }
}