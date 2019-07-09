import { QleKindWizardSelectionComponent } from "./qle_kind_deactivation_form.component";
import { ElementRef, Injector, InjectionToken, Type, InjectFlags } from '@angular/core';
import { Observable } from "rxjs";

class MockInjector extends Injector {
   get<T>(token: Type<T> | InjectionToken<T>, notFoundValue?: T, flags?: InjectFlags): T {
     return notFoundValue;
   }
}

class MockElementRef extends ElementRef {

}

describe('QleKindWizardSelectionComponent', () => {
  it("is created successfully", () => {
    var component = new QleKindWizardSelectionComponent(
      new MockInjector(),
      null,
      new MockElementRef(null));
  });

  it("initializes successfully", () => {
    var qle_kind_wizard_selection_item = {

    };
    var component = new QleKindDeactivationFormComponent(
      new MockInjector(),
      null,
      new MockElementRef(myElement));
    component.ngOnInit();
    expect(component.selectedCategory).not.toBe(null);
    expect(component.filteredItems).toEqual(null);
  });
});
