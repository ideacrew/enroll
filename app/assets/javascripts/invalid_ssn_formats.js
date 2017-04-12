$(document).on('ready page:load', function () {
  $('#person_ssn').blur(function(){
    var user_input = $(this).val();

    // RegEx below checks for the invalid formats.
    var reg_ex = new RegExp("^(?!000|666|9\\d{2})\\d{3}-(?!00)\\d{2}-(?!0{4})\\d{4}$");
    var is_valid = reg_ex.test(user_input);
    var array = user_input.split('').map(function(val){return parseInt(val);});
    user_input = array.filter(Boolean);

    // checks if user entered sequential number as SSN
    var seq_size = 0
    var is_sequential = false;
    for(var i=0; i<9; i++) {
      (function sequential() {
        if (user_input[i+1] == user_input[i] + 1){
          seq_size += 1;
          if (seq_size == 5){
            is_sequential = true;
            return;
          }
        } else {
          seq_size = 0;
        }
      })();
    }

    // checks if user entered same digits in all positions in SSN
    var same_num_size = 0;
    var is_same_number = false;
    for(var i=0; i<9; i++) {
      (function same_number() {
        if (user_input[i+1] == user_input[i]){
          same_num_size += 1;
          if (same_num_size == 5){
            is_same_number = true;
            return;
          }
        } else {
          same_num_size = 0;
        }
      })();
    }

    if ( user_input.length != 0 && (!is_valid || is_sequential || is_same_number)) {
      $( function() {
        $( "#dialog" ).dialog();
      });
      $(this).val("");
    }
  });
});
