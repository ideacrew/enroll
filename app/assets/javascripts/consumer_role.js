$(document).on('change', "#person_no_dc_address, #dependent_no_dc_address, #no_dc_address", function(){
  if (this.checked) {
    $(this).parents('#address_info').find('.home-div.no-dc-address-reasons').show();
    $('#radio_homeless').attr('required', true);
    $('#radio_outside').attr('required', true);
    $(this).parents('#address_info').find('.address_required').removeAttr('required');
  } else {
    $('#radio_homeless').attr('required', false);
    $('#radio_outside').attr('required', false);
    $(this).parents('#address_info').find('.home-div.no-dc-address-reasons').hide();
    $(this).parents('#address_info').find('.address_required').attr('required', true);
  };
});
