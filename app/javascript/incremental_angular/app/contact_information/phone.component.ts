import { Component, Input } from '@angular/core';
import { FormGroup, FormControl, AbstractControl, Validators } from '@angular/forms';

@Component({
  selector: 'phone-component',
  templateUrl: './phone.component.html'
})
export class PhoneComponent {
  @Input("parentForm")
  public parentForm: FormGroup;

  @Input("prefix")
  public prefix: string = "";

  public phoneGroup: FormGroup;

  ngOnInit() {
    this.phoneGroup = new FormGroup({
      phone_area_code: new FormControl('', Validators.required),
      phone_number: new FormControl('', Validators.required),
      phone_extension: new FormControl('')
    });
    this.parentForm.addControl('phone', this.phoneGroup);
  }

  errorClassFor(control: AbstractControl) : String {
    return (this.hasErrors(control) ? " has-error" : "");
  }

  public hasErrors(control : AbstractControl) : Boolean {
    return ((control.touched || control.dirty) && !control.valid);
  }
}