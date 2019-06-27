import { Component, Input } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

@Component({
  selector: 'admin-qle-deactivation-form',
  templateUrl: './qle_deactivation_form.component.html'
})
export class QleDeactivationFormComponent {
  public parentForm: FormGroup;
  public deactivateQleKindForm: FormGroup;

  ngOnInit() {
    var qle_deactivation_fields = new FormGroup({
      start_on: new FormControl('', Validators.required),
      end_on: new FormControl('', Validators.required),
    });
  }
}
