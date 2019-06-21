import { Component, Input } from '@angular/core';
import { FormGroup, AbstractControl, FormControl, Validators } from '@angular/forms';

@Component({
  selector: 'ach-information',
  templateUrl: './ach_information.component.html'
})
export class AchInformationComponent {
  @Input("parentForm")
  public parentForm: FormGroup;

  public achGroup: FormGroup;

  ngOnInit() {
    this.achGroup = new FormGroup({
      ach_account: new FormControl(''),
      ach_routing: new FormControl(''),
      ach_routing_confirmation: new FormControl(''),
    });
    this.parentForm.addControl("ach_information", this.achGroup);
  }

  public errorClassFor(control : AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
}