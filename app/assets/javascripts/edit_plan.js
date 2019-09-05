$(document).on("ready ajax:success", function() {

  $("#agreement_action-confirm-yes").click(function(){
    $(".interaction-click-control-action-confirm").attr("disabled", false);
    $("#action-confirm-date").attr("hidden", false);
  });
  $("#agreement_action-confirm-no").click(function(){
    $(".interaction-click-control-action-confirm").attr("disabled", true);
    $("#action-confirm-date").attr("hidden", true);
  });

  $('#cancel-button').click(function(e){
    e.preventDefault();
    $('.confirmation').addClass('hidden');
    $('#action-confirm').removeClass('hidden');
    $('.action-msg').addClass('hidden');
    $('#cancel-msg').removeClass('hidden');
    $('#cancel-form').removeClass('hidden');
    $('#calendar-div').addClass('hidden');
    $('#applied-aptc-text').addClass('hidden');
  });

});
