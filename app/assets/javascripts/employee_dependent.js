$(document).ready(function() {
  $('.remove-new-employee-dependent').each(function(idx, ele) {
    $(ele).click(function() {
    var targetElementId = $(ele).attr("data-target");
    $(targetElementId).remove();
    $("#dependent_buttons").removeClass('hidden');
    return false;
    });
  });
});
