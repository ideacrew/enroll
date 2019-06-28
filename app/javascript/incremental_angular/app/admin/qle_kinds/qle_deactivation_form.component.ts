import { Component, Injector, ElementRef } from '@angular/core';

@Component({
  selector: 'admin-qle-deactivation-form',
  templateUrl: './qle_deactivation_form.component.html'
})
export class QleDeactivationFormComponent {
  public qleToDeactivate : string | null = null;
  constructor(injector: Injector, private _elementRef : ElementRef) {

  }
  ngOnInit() {
    var qleToDeactivateJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-qle-to-deactivate");
    if (qleToDeactivateJson != null) {
      this.qleToDeactivate = JSON.parse(qleToDeactivateJson)
    }
  }

  submitDeactivation() {
    alert("Submitted deactivation!")
  }
}
