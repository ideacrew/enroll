$(function() {
  $("input#terminated_yes").change(function(){
    $("tr.terminated_true").show();
    $("tr.terminated_false").hide();
  });

  $("input#terminated_no").change(function(){
    $("tr.terminated_false").show();
    $("tr.terminated_true").hide();
  });

  $("input#terminated_yes").trigger("change");
})
