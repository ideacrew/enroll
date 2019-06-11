import { Component, Input } from '@angular/core';
import { FormGroup, AbstractControl, FormControl, Validators } from '@angular/forms';
import {  OfficeLocationOwnerComponent } from "./office_location_owner_component";

@Component({
  selector: 'office-location',
  templateUrl: './office_location.component.html'
})
export class OfficeLocationComponent {
  @Input("parentForm")
  public parentForm: FormGroup;

  @Input("index")
  public index: number | null;

  @Input("officeLocation")
  public officeLocation: FormGroup;

  @Input("stateList")
  public stateList : String[] = [];

  @Input("parentComponent")
  public parentComponent : OfficeLocationOwnerComponent | null;

  public kinds: string[] = [
    "SELECT KIND",
    "Mailing",
    "Branch"
  ];

  ngOnInit() {
    var address = new FormGroup({
      address_1: new FormControl('', Validators.required),
      address_2: new FormControl(''),
      city: new FormControl('', Validators.required),
      state: new FormControl('SELECT STATE'),
      zip: new FormControl('', Validators.required)
      });
    if (this.hasParentComponent()) {
      this.officeLocation.addControl(
        "kind",
        new FormControl("SELECT KIND", Validators.required)
      );
    }
    this.officeLocation.addControl("address", address);
  }

  errorClassFor(control: AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  hasParentComponent() : Boolean {
    return this.parentComponent != null;
  }

  address1Classes() : string {
    if(this.hasParentComponent()) {
      return "col-md-9 col-sm-6";
    }
    return "col-md-12 col-sm-12";
  }

  public removeFromParent() {
    if ((this.parentComponent != null) && (this.index != null)) {
      this.parentComponent.removeOfficeLocation(this.index);
    }
  }

  public addressGroup() :  FormGroup {
    return this.officeLocation.get("address") as FormGroup;
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
}