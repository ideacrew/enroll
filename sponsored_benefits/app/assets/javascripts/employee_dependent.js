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

$(document).on('change', '#dependent_same_with_primary', function(){
  var target = $(this).parents('#dependent-address').find('#dependent-home-address-area');
  if ($(this).is(':checked')) {
    $(target).hide();
    $(target).find("#address_info .address_required").removeAttr('required');
  } else {
    $(target).show();
    if (!$(target).find("#dependent_no_dc_address").is(':checked')){
      $(target).find("#address_info .address_required").attr('required', true);
    };
  }
});
