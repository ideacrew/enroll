$(document).ready(function() {
  $('.input-spinner .btn:first-of-type').on('click', function() {
    input_value= parseInt($('.input-spinner input').val(), 10);
    if(input_value > 0 && input_value < 36){
      $('.input-spinner input').val( input_value + 1);
    }
  });
  $('.input-spinner .btn:last-of-type').on('click', function() {
    input_value= parseInt($('.input-spinner input').val(), 10);
    if(input_value > 1 && input_value <= 36){
      $('.input-spinner input').val(input_value- 1);
    }
  });
});