$(document).on('ready page:load', function () {
  $('#person_ssn').blur(function(){
    var user_input = $(this).val();
    end_val = 999;
    invalid_array = [000, 666];
    for(var start_val=900;start_val<=end_val;start_val++){
      invalid_array.push(start_val)
    }
// Invalid array has all the invalid sequences
    var is_invalid = $.inArray(parseInt(user_input.split('-')[0]), invalid_array) > -1 || $.inArray(parseInt(user_input.split('-')[1]), invalid_array) > -1 || $.inArray(parseInt(user_input.split('-')[2]), invalid_array) > -1

    var array = user_input.split('').map(function(val){return parseInt(val);});
    user_input = array.filter(Boolean);

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

    if ( user_input.length != 0 && (is_invalid || is_sequential || is_same_number)) {
      $( function() {
        $( "#dialog" ).dialog();
      });
      $(this).val("");
    }
  });
});
