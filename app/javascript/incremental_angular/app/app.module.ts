import { BrowserModule } from '@angular/platform-browser';
import { NgModule, Injector } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { createCustomElement } from '@angular/elements';
import { HttpClientModule } from '@angular/common/http';
import { NgxMaskModule } from 'ngx-mask'

export const options = {};

import { BrokerAgencyProfileCreateComponent } from './broker_agency_profile/broker_agency_profile_create.component';
import { TrustedHtmlPipe } from './trusted_html_pipe';
import { PhoneComponent } from './contact_information/phone.component';
import { OfficeLocationComponent } from './office_locations/office_location.component';
import { AchInformationComponent } from './financial/ach_information.component';
import { BrokerAgencyProfileResourceService } from './broker_agency_profile/broker_agency_profile_resource.service'
import { FieldErrorsComponent } from './errors/field_errors.component';
import { QleKindWizardComponent } from  './admin/qle_kinds/qle_kind_wizard.component';
import { QleKindDeactivationFormComponent } from  './admin/qle_kinds/qle_kind_deactivation_form.component';

import { ErrorLocalizer } from './error_localizer';

@NgModule({
  declarations: [
    AchInformationComponent,
    BrokerAgencyProfileCreateComponent,
    FieldErrorsComponent,
    PhoneComponent,
    OfficeLocationComponent,
    QleKindWizardComponent,
    TrustedHtmlPipe,
    QleKindDeactivationFormComponent
  ],
  entryComponents: [
    BrokerAgencyProfileCreateComponent,
    QleKindWizardComponent,
    QleKindDeactivationFormComponent
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    FormsModule,
    ReactiveFormsModule,
    NgxMaskModule.forRoot(options)
  ],
  providers: 
  [
    BrokerAgencyProfileResourceService.provides('BrokerAgencyProfileCreationService'),
    ErrorLocalizer
  ]
})
export class AppModule {
  constructor(private injector: Injector) {
  }
  ngDoBootstrap() {
    const bapc_custom = createCustomElement(BrokerAgencyProfileCreateComponent, {injector: this.injector });
    customElements.define("broker-agency-profile-create",bapc_custom);
    const qlewk_custom = createCustomElement(QleKindWizardComponent, {injector: this.injector });
    customElements.define("admin-qle-management-wizard",qlewk_custom);
    const qle_kind_deactivation_form_custom = createCustomElement(QleKindDeactivationFormComponent, { injector: this.injector });
    customElements.define("admin-qle-kind-deactivation-form",qle_kind_deactivation_form_custom);
  
  }
}