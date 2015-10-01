$(document).on('change', "#person_no_dc_address, #dependent_no_dc_address", function(){
  if (this.checked) {
    $(this).parents('#address_info').find('.home-div.no-dc-address-reasons').show();
    $(this).parents('#address_info').find('.address_required').removeAttr('required');
  } else {
    $(this).parents('#address_info').find('.home-div.no-dc-address-reasons').hide();
    $(this).parents('#address_info').find('.address_required').attr('required', true);
  };
});
