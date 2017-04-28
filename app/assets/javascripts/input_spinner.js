$(document).on('click', '.input-spinner .btn:first-of-type' , function() {
    input_value= parseInt($('.input-spinner input').val(), 10);
    if(input_value > 0 && input_value < 36){
      $('.input-spinner input').val( input_value + 1);
    }
});

$(document).on('click', '.input-spinner .btn:last-of-type' , function() {
    input_value= parseInt($('.input-spinner input').val(), 10);
    if(input_value > 1 && input_value <= 36){
      $('.input-spinner input').val(input_value- 1);
    }
});