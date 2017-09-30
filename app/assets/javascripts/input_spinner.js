$(document).on('click', '.input-spinner .btn:first-of-type' , function() {
    input_value= parseInt($('.input-spinner input').val(), 10);
    if(input_value > 0 && input_value < 36){
      $('.input-spinner input').val( input_value + 1);
      d = new Date($.now());
      d = new Date(d.getFullYear(), d.getMonth(), 1)
      d = d.setMonth(d.getMonth() + input_value+1);
      d = new Date(d);
      d = new Date(d.getFullYear(), d.getMonth() + 1, 0);
      $('#max_cobra_date').html((d.getMonth() + 1) + '/' + d.getDate() + '/' +  d.getFullYear());
    }
});

$(document).on('click', '.input-spinner .btn:last-of-type' , function() {
    input_value= parseInt($('.input-spinner input').val(), 10);
    if(input_value > 1 && input_value <= 36){
      $('.input-spinner input').val(input_value- 1);
      // var sep122017 = new Date(2017, 9, 12);
      // var getmonths  = sep122017.setMonth(sep122017.getMonth()+8);
       d = new Date($.now());
      d = new Date(d.getFullYear(), d.getMonth(), 1)
      d = d.setMonth(d.getMonth() + input_value - 1);
      d = new Date(d);
      d = new Date(d.getFullYear(), d.getMonth() + 1, 0);
      $('#max_cobra_date').html((d.getMonth() + 1) + '/' + d.getDate() + '/' +  d.getFullYear());
      
    }
});