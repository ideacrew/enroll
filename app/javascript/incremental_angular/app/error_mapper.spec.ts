import { FormControl, FormGroup, FormArray } from '@angular/forms'; 
import { ErrorResponse, ErrorMapper } from './error_mapper';

describe('ErrorMapper', () => {

  it("maps errors to a targeted child component", () => {
    var control = new FormControl("");
    var group = new FormGroup({
      control: control
    });
    var errors : ErrorResponse = {
      control: ["an error that should be put on the control"]
    };
    var e_mapper =  new ErrorMapper();
    e_mapper.processErrors(group, errors);
    var first_error_key  = Object.keys(control.errors)[0];
    expect(control.getError(first_error_key)).toBe("an error that should be put on the control")
  });

  it("maps errors to a targeted child component in a child component group", () => {
    var control = new FormControl("");
    var group = new FormGroup({
      child_group: new FormGroup({
        control: control
      })
    });
    var errors : ErrorResponse = {
      child_group: {
              control: ["an error that should be put on the control"]
      }
    };
    var e_mapper =  new ErrorMapper();
    e_mapper.processErrors(group, errors);
    var first_error_key  = Object.keys(control.errors)[0];
    expect(control.getError(first_error_key)).toBe("an error that should be put on the control")
  });

  it("maps errors to a targeted child component in a child component array group", () => {
    var control = new FormControl("");
    var child_group = new FormGroup({
      control: control
    });
    child_group.addControl("control", control);
    var group = new FormGroup({
      child_array: new FormArray([
        child_group
      ])
    });
    var errors : ErrorResponse = {
      child_array: [<ErrorResponse>{
              control: ["an error that should be put on the control"]
      }]
    };
    var e_mapper =  new ErrorMapper();
    e_mapper.processErrors(group, errors);
    var first_error_key  = Object.keys(control.errors)[0];
    expect(control.getError(first_error_key)).toBe("an error that should be put on the control")
  });

  it("maps errors to a targeted child component in a child component array group, when it gets rails formatted errors", () => {
    var control = new FormControl("");
    var child_group = new FormGroup({
      control: control
    });
    var other_child_group = new FormGroup({
      other_control: new FormControl("")
    });
    child_group.addControl("control", control);
    var group = new FormGroup({
      child_array: new FormArray([
        other_child_group,
        child_group
      ])
    });
    var errors : ErrorResponse = {
      child_array: {
        "1": <ErrorResponse>{
              control: ["an error that should be put on the control"]
         }
      }
    };
    var e_mapper =  new ErrorMapper();
    e_mapper.processErrors(group, errors);
    var first_error_key  = Object.keys(control.errors)[0];
    expect(control.getError(first_error_key)).toBe("an error that should be put on the control")
  });

  it("maps errors to a targeted child component in a child component array", () => {
    var control = new FormControl("");
    var group = new FormGroup({
      child_array: new FormArray([
        control
      ])
    });
    var errors : ErrorResponse = {
      child_array: [
        ["an error that should be put on the control"]
      ]
    };
    var e_mapper =  new ErrorMapper();
    e_mapper.processErrors(group, errors);
    var first_error_key  = Object.keys(control.errors)[0];
    expect(control.getError(first_error_key)).toBe("an error that should be put on the control")
  });
});