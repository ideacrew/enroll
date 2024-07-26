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
    $(target).addClass('hidden');
    $(this).parents('#dependent-address').find('#home-info').addClass('hidden');
    $("#dependent_addresses_0_address_1, #dependent_addresses_0_zip, #dependent_addresses_0_city").each(function() {
      $(this).prop('required', false);
    })
    $(target).find("#address_info .address_required").removeAttr('required');
  } else {
    $(target).removeClass('hidden');
    $(this).parents('#dependent-address').find('#home-info').removeClass('hidden');
    $("#dependent_addresses_0_address_1, #dependent_addresses_0_zip, #dependent_addresses_0_city").each(function() {
      $(this).prop('required', true);
    })
    if (!$(target).find("#dependent_no_dc_address").is(':checked')){
      $(target).find("#address_info .address_required").attr('required', true);
    };
  }
});
