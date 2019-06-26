import { Component, Injector, ElementRef, Inject, ViewChild } from '@angular/core';
import { QleKindEditResource } from './qle_kind_edit_data';
import { FormGroup, FormControl, AbstractControl, Validators } from '@angular/forms';
import { QleKindUpdateService } from '../qle_kind_services';
import { ErrorLocalizer } from '../../../error_localizer';
import { ErrorMapper, ErrorResponse } from '../../../error_mapper';
import { HttpResponse } from "@angular/common/http";

@Component({
  selector: 'admin-qle-kind-edit-form',
  templateUrl: './qle_kind_edit_form.component.html'
})
export class QleKindEditFormComponent {
  public qleKindToEdit : QleKindEditResource | null = null;
  public updateUri : string | null = null;
  public editFormGroup : FormGroup = new FormGroup({});
  @ViewChild('headerRef') headerRef: ElementRef;

  constructor(
    injector: Injector,
    @Inject("QleKindUpdateService") private updateService : QleKindUpdateService,
    private errorLocalizer: ErrorLocalizer,
    private _elementRef : ElementRef) {
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }

  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  ngOnInit() {
    var qleKindToEditJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-to-edit");
    if (qleKindToEditJson != null) {
      this.qleKindToEdit = JSON.parse(qleKindToEditJson)
      if (this.qleKindToEdit != null) {
        this.editFormGroup.addControl(
          "_id",
          new FormControl(this.qleKindToEdit._id),
        )
        this.editFormGroup.addControl(
          "title",
          new FormControl(this.qleKindToEdit.title),
        )
        // Add the other attributes to pull and edit here
      }
    }
    var submissionUriAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-kind-edit-url");
    if (submissionUriAttribute != null) {
      this.updateUri = submissionUriAttribute;
    }
  }

  hasResource() {
    return this.qleKindToEdit != null;
  }

  submitUpdate() {
    var form = this;
    var errorMapper = new ErrorMapper();
    if (this.editFormGroup.valid) {
      if (this.updateUri != null) {
        var invocation = this.updateService.submitUpdate(this.updateUri, this.editFormGroup.value);
        invocation.subscribe(
          function(data: HttpResponse<any>) {
            var location_header = data.headers.get("Location");
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
        form.headerRef.nativeElement.scrollIntoView();
    }
  }
}
