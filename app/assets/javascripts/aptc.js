$(document).on('click', "a#calculate_available_aptc", function(){

  var aptc_applied = parseFloat($('input#aptc_applied').val());
  //alert("aptc_applied is : " + aptc_applied);
  var max_aptc = parseFloat($('input#max_aptc').val());


  if (!isNaN(aptc_applied) && !isNaN(max_aptc)){
    $('input.aptc_applied').val(aptc_applied);
    $('input.max_aptc').val(max_aptc);
    $('input.avalaible_aptc').val(max_aptc - aptc_applied);
  }
});
