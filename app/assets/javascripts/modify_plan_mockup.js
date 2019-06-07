$(document).ready(function() {

  $('#terminate-button').click(function(e){
    e.preventDefault();
    $('.confirmation').addClass('hidden');
    $('#terminate-confirm').removeClass('hidden');
    $('#calendar-div').removeClass('hidden');
    // $('#btn-terminate').val('Terminate');
    $('#enter-text').removeClass('hidden').html('Enter the date of termination');
    $('#term_date').val('');
    $('#applied-aptc-text').addClass('hidden');
  });

  $('#cancel-button').click(function(e){
    e.preventDefault();
    $('.confirmation').addClass('hidden');
    $('#cancel-confirm').removeClass('hidden');
    $('#calendar-div').removeClass('hidden');
    // $('#btn-terminate').val('Cancel');
    $('#enter-text').removeClass('hidden').html('Enter the date of cancellation');
    $('#term_date').val('');
    $('#applied-aptc-text').addClass('hidden');
  });

  $('#aptc-button').click(function(e){
    e.preventDefault();
    $('.confirmation').addClass('hidden');
    $('#aptc-confirm').removeClass('hidden');
    $('#calendar-div').removeClass('hidden');
    // $('#btn-terminate').val('Confirm APTC');
    $('#enter-text').addClass('hidden');
    $('#term_date').val('07/01/2019');
    $('#applied-aptc-text').removeClass('hidden');
  });

  $('#applied_pct_1').change(function(){
    calculatePercent('#applied_pct_1', 100);
  });
  $('#aptc_applied_5cf6c9ec9ee4f43836000020').change(function(){
    calculatePercent('#aptc_applied_5cf6c9ec9ee4f43836000020', 1);
  });

  function calculatePercent(selector, multiplier) {
    var percent = parseFloat($(selector).val()).toFixed(2) * multiplier;
    $('#aptc_applied_pct_1_percent').val(percent + '%');
    $('#aptc_applied_5cf6c9ec9ee4f43836000020').val(percent);
  }

});
