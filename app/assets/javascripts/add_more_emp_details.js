$(document).ready(function() {
    var max_fields      = 5; //maximum input boxes allowed
    var wrapper         = $(".input_fields_wrap"); //Fields wrapper
    var add_button      = $(".add_field_button"); //Add button ID

    var x = 1; //initlal text box count
    $(add_button).click(function(e){ //on add input button click
        e.preventDefault();
        if(x < max_fields){ //max input box allowed
            x++; //text box increment
            $(wrapper).append('<div id="emp_details_group" style="margin-top: 10px;"><span><input type="text" class="form-control" name="dob[]" placeholder="Please enter DOB this format DD/MM/YYYY"/></span> <span> Relationship:  <select name="emp_relation[]"> <option value="employee">Employee</option> <option value="dependent">Dependent</option> </select> </span>  <span><input type="text" class="form-control" name="first_name[]" placeholder="Please enter First Name"/></span> <span><input type="text" class="form-control" name="middle_name[]" placeholder="Please enter Middle Name"/></span> <span><input type="text" class="form-control" name="last_name[]" placeholder="Please enter Last Name"/></span> <span><input type="text" class="form-control" name="name_sfx[]" placeholder="Please enter SFX"/></span> <span> <select name="gender[]"> <option value="male">Male</option> <option value="female">Female</option> </select> </span>  <span><input type="text" class="form-control" name="ssn[]" placeholder="Please enter SSN"/></span> <a class="remove_field" style="cursor:pointer;">Remove</a></div>'); //add input box
        }
    });

    $(wrapper).on("click",".remove_field", function(e){ //user click on remove text
        e.preventDefault(); $(this).parent('div#emp_details_group').remove(); x--;
    })
});