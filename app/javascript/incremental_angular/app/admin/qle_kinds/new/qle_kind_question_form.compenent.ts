import { Component, Injector, ElementRef, Inject, ViewChild  } from '@angular/core';
import { QleKindQuestionResource } from './qle_kind_creation_data';
import { FormGroup, FormControl, AbstractControl, Validators } from '@angular/forms';
import { QleKindQuestionService } from '../qle_kind_services';
import { ErrorLocalizer } from '../../../error_localizer';
import { ErrorMapper, ErrorResponse } from '../../../error_mapper';
import { HttpResponse } from "@angular/common/http";


@Component({
  selector: 'admin-qle-kind-creation-form',
  templateUrl: './qle_kind_creation_form.component.html'
})
export class QleKindQuestionFormComponent {
  public qleKindToCreate : QleKindQuestionResource | null = null;
  public creationFormGroup : FormGroup = new FormGroup({});
  public creationUri : string | "";
  @ViewChild('headerRef') headerRef: ElementRef;

  constructor(
     injector: Injector,
     private _elementRef : ElementRef,
     @Inject("QleKindQuestionService") private QuestionService : QleKindQuestionService,
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
        this.creationFormGroup.addControl(
          "title",
          new FormControl(""),
        )
        this.creationFormGroup.addControl(
          "tool_tip",
          new FormControl(""), 
        )
        this.creationFormGroup.addControl(
          "action_kind",
          new FormControl(""),  
        )
        this.creationFormGroup.addControl(
          "reason",
          new FormControl(""),  
        )
        this.creationFormGroup.addControl(
          "market_kind",
          new FormControl(""),  
        )
        this.creationFormGroup.addControl(
          "is_self_attested",
          new FormControl(""),  
        )
    var submissionUriAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-creation-url");
      if (submissionUriAttribute != null) {
        this.creationUri = submissionUriAttribute;
      }
    }

  submitQuestion() {
    var form = this;
    var errorMapper = new ErrorMapper();
    if (this.creationFormGroup != null) {
      if (this.creationFormGroup.valid) {
        console.log(this.creationFormGroup.value)
        // var invocation = this.QuestionService.submitQuestion(this.creationUri, this.creationFormGroup.value);
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
