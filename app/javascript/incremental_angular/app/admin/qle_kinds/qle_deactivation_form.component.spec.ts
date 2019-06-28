import { QleKindWizardComponent } from "./qle_deactivation_form.component";
import { ElementRef, Injector, InjectionToken, Type, InjectFlags } from '@angular/core';

class MockInjector extends Injector {
   get<T>(token: Type<T> | InjectionToken<T>, notFoundValue?: T, flags?: InjectFlags): T {
     return notFoundValue;
   }
}

class MockElementRef extends ElementRef {

}

describe('QleKindWizardComponent', () => {
  it("is created successfully", () => {
    var component = new QleDeactivationFormComponent(new MockInjector(), new MockElementRef(null));
  });
});
