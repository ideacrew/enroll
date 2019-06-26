import { Component, Injector, ElementRef, ViewChild } from '@angular/core';
import { DropdownOption } from 'app/dropdown_option';

@Component({
  selector: 'admin-qle-management-wizard',
  templateUrl: './qle_kind_wizard.component.html'
})
export class QleKindWizardComponent {
  public editableList : Array<DropdownOption> = [];
  public deactivatableList : Array<DropdownOption> = [];
  private newLocation : string | null = null;
  private selectedAction : string | null = null;
  @ViewChild('editSelection') editSelection : ElementRef;
  @ViewChild('deactivateSelection') deactivateSelection : ElementRef;

  constructor(injector: Injector, private _elementRef : ElementRef) {

  }

  ngOnInit() {
    var editableListJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-editable-list");
    if (editableListJson != null) {
      this.editableList = JSON.parse(editableListJson);
    }
    var deactivatableListJson = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-deactivatable-list");
    if (deactivatableListJson != null) {
      this.deactivatableList = JSON.parse(deactivatableListJson);
    }
    var newLocationAttribute = (<HTMLElement>this._elementRef.nativeElement).getAttribute("data-new-location");
    if (newLocationAttribute != null) {
      this.newLocation = newLocationAttribute;
    }
  }

  selectAction(action : string) {
    this.selectedAction = action;
  }

  submit() {
    if (this.selectedAction == "new") {
      if (this.newLocation != null) {
        window.location.href = this.newLocation;
      }
    } else if (this.selectedAction == "edit") {
      var editLocation = this.editSelection.nativeElement.value;
      if (editLocation != null) {
        window.location.href = editLocation;
      }
    } else if (this.selectedAction == "deactivate") {
      var deactivateLocation = this.deactivateSelection.nativeElement.value;;
      if (deactivateLocation != null) {
        window.location.href = deactivateLocation;
      }
    }
  }

  showEdit() {
    return(this.selectedAction == "edit");
  }

  showDeactivate() {
    return(this.selectedAction == "deactivate");
  }
}