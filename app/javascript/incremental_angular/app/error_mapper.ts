import { ValidationErrors, AbstractControl, FormArray, FormGroup } from "@angular/forms";
import { formGroupNameProvider } from '@angular/forms/src/directives/reactive_directives/form_group_name';

export interface ErrorResponse {
  [key: string]: any;
}

export class ErrorMapper {
  public invalidParentForm(currentscope: FormGroup) {
    var err_list : ValidationErrors = {};
    err_list["server_validation_child_control_form_errors"] = "Errors in the data below. Each field in error is highlighted.";
    currentscope.setErrors(err_list);
  }

  cascadeTouch(control : AbstractControl) {
    if (control instanceof FormGroup) {
      var fg = control as FormGroup;
      var ks = Object.keys(fg.controls)
      for (var i = 0; i < ks.length; i++) {
        var child_fg = fg.get(ks[i]);
        if (child_fg != null) {
          this.cascadeTouch(child_fg);
        }
      }
    } else if (control instanceof FormArray) {
      var fa = control as FormArray;
      for (var i = 0; i < fa.length; i++) {
        var child_fa = fa.at(i);
        if (child_fa != null) {
          this.cascadeTouch(child_fa);
        }
      }
    }
    control.markAsTouched();
  }

  public mapParentErrors(currentscope: FormGroup, errors: ErrorResponse) {
    var controlNames = Object.keys(currentscope.controls);
    var base_error_keys = Object.keys(errors).filter(function(err_key) {
      return controlNames.indexOf(err_key) < 0;
    });
    var other_error_keys = Object.keys(errors).filter(function(err_key) {
      return controlNames.indexOf(err_key) >= 0;
    });
    var err_list : ValidationErrors = {};
    if (base_error_keys.length > 0) {
      base_error_keys.forEach(function(base_error_key) {
        var err_msgs = errors[base_error_key];
        if (err_msgs != null) {
          for(var i = 0; i < err_msgs.length; i++) {
            err_list[("server_validation_" + base_error_key.toString() + "_" + i.toString())] = err_msgs[i];
          }
        }
      });
    }
    if (other_error_keys.length > 0) {
      err_list["server_validation_child_control_form_errors"] = "Errors in the data below. Each field in error is highlighted.";
    }
    var error_key_length = Object.keys(err_list).length;
    if (error_key_length > 0) {
      currentscope.setErrors(err_list);
    }
  }

  public processErrors(currentscope: AbstractControl, errors : ErrorResponse) {
    var keys = Object.keys(errors);
    var propChecker = this;
    keys.forEach(
       function(k) {
         if (propChecker.hasKey(errors, k)) {
         var e_val = errors[k];
         if (Array.isArray(e_val)) {
           var e_array = <Array<any>>e_val;
           if (propChecker.allStringChildren(e_array)) {
             // Leaf Node - a plain array of strings
             var s_errors = <Array<string>>e_array;
             var child = currentscope.get(k);
             var err_list : ValidationErrors = {};
             if (child != null) {
               for(var i = 0; i < s_errors.length; i++) {
                 err_list[("server_validation_" + i.toString())] = s_errors[i];
               }
               child.setErrors(err_list, {emitEvent: true});
               child.markAsTouched();
             } 
           } else if (propChecker.allBareChildStrings(e_array)) {
            // Bare control array
            var child_list = (currentscope.get(k) as FormArray);
            for (var i = 0; i < child_list.length; i++) {
              var child_control = child_list.at(i);
              var child_errs = e_array[i];
              if (Array.isArray(child_errs)) {
                var c_err_list : ValidationErrors = {};
                for (var j = 0; j < child_errs.length; j++) {
                  c_err_list[("server_validation_" + j.toString())] = child_errs[i];
                }
                child_control.setErrors(c_err_list, {emitEvent: true});
              }
            }
           } else {
             // Array of child form group error messages
             var child_list = (currentscope.get(k) as FormArray);
             for (var i = 0; i < child_list.length; i++) {
               var c_control = child_list.at(i);
               propChecker.processErrors(c_control, e_array[i]);
             }
           }
         } else {
           // Named child form group
           var child = currentscope.get(k);
           if (child != null) {
            propChecker.processErrors(child, e_val);
           } 
         }
        }
       }
    );
  }

  private allBareChildStrings(a : Array<any>) : boolean {
    var propChecker = this;
    return a.every(function(item) {
      if (Array.isArray(item)) {
        return (propChecker.allStringChildren(item));
      }
      return false;
    });
  }

  private hasKey<O>(obj: O, key: keyof any): key is keyof O {
    return key in obj
  }

  private allStringChildren(a : Array<any>) : boolean {
    return a.every(function(item)  {
      return (typeof item === "string");
    });
  }
}