import { Component, Injector, ElementRef, Inject, ViewChild  } from '@angular/core';
// import { QleKindQuestionResource } from './qle_kind_question_data';
import { FormGroup, FormControl, AbstractControl, Validators } from '@angular/forms';
import { ErrorLocalizer } from '../../../error_localizer';
import { ErrorMapper, ErrorResponse } from '../../../error_mapper';
import { HttpResponse } from "@angular/common/http";


@Component({
  selector: 'qle-question-form',
  templateUrl: './qle_kind_question_form.component.html'
})
export class QleKindQuestionFormComponent {
  public questionFormGroup : FormGroup = new FormGroup({});
  public question : string | null = null;
  @ViewChild('headerRef') headerRef: ElementRef;

  constructor(
     injector: Injector,
     private _elementRef : ElementRef,
     ) {

  }
  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }
  ngOnInit() {
        this.questionFormGroup.addControl(
          "question",
          new FormControl(""),
        )
    }

  submitQuestion() {
    var form = this;
    var errorMapper = new ErrorMapper();
    if (this.questionFormGroup != null) {
      if (this.questionFormGroup.valid) {
        console.log(this.questionFormGroup.value)
        // var invocation = this.QuestionService.submitQuestion(this.questionUri, this.questionFormGroup.value);
        // invocation.subscribe(
        //   function(data: HttpResponse<any>) {
        //     var location_header = data.headers.get("Location");
        //     if (location_header != null) {
        //       window.location.href = location_header;
        //     }
        //   },
        //   function(error) {
        //     errorMapper.mapParentErrors(form.questionFormGroup, <ErrorResponse>(error.error.errors));
        //     errorMapper.processErrors(form.questionFormGroup, <ErrorResponse>(error.error.errors));
        //     form.headerRef.nativeElement.scrollIntoView();
        //   }
        // )
      }
    }
  }
}
