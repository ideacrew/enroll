import { QleKindCreationFormComponent } from "./qle_kind_creation_form.component";
import { QleKindCreationResource } from './qle_kind_creation_data';
import { Component, Injector, ElementRef, Inject, ViewChild  } from '@angular/core';
import { FormGroup, FormControl, AbstractControl, FormArray, FormBuilder, Validators } from '@angular/forms';
import { QleKindCreationService } from '../qle_kind_services';
import { ErrorLocalizer } from '../../../error_localizer';
import { ErrorMapper, ErrorResponse } from '../../../error_mapper';
import { QleKindQuestionFormComponent } from './qle_kind_question_form.component';
import { __core_private_testing_placeholder__ } from '@angular/core/testing';
import { HttpResponse } from "@angular/common/http";
import { Observable } from "rxjs";


class MockQleKindCreationService {
  public submitCreate(post_uri: string, obj_data : object) : Observable<HttpResponse<any>> {
    return null;
  }

}

describe('QleKindCreationFormComponent', () => {
  it("is created successfully", () => {
    var component = new QleKindCreationFormComponent(
     new Injector(),
     new ElementRef(null),
     new FormBuilder(),
     new MockQleKindCreationService(),
    )
  });

  it("successfully passes through the question and responses params", () => {
    var component = new QleKindCreationFormComponent(
     new Injector(),
     new ElementRef(null),
     new FormBuilder(),
     new MockQleKindCreationService(),
    )
    expect(component.submitCreation())

  })
});

