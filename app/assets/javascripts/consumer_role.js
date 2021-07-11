$(document).on('change', "#person_no_dc_address, #dependent_no_dc_address, #no_dc_address", function(){
  if (this.checked) {
    $('#radio_homeless').attr('required', true);
    $('#radio_outside').attr('required', true);
    $(this).parents('#address_info').find('.address_required').removeAttr('required');
  } else {
    $('#radio_homeless').attr('required', false);
    $('#radio_outside').attr('required', false);
    $(this).parents('#address_info').find('.address_required').attr('required', true);
  };
});

$(document).on('ready', function(){
  $(document).on("click", ".interaction-choice-control-value-agreement-agree", function(){
      $(".interaction-click-control-continue").attr("href", "/insured/interactive_identity_verifications/new");
      $('.aut_cons_text').parents('.row-form-wrapper').addClass('hide');
  });

  $(document).on("click", ".interaction-choice-control-value-agreement-disagree", function(){
      $(".interaction-click-control-continue").attr("href", "/insured/consumer_role/upload_ridp_document");
      $('.aut_cons_text').parents('.row-form-wrapper').removeClass('hide');
  });

  $(document).on('change', "#person_is_homeless, #dependent_is_homeless", function(){
    if ($(this).prop('checked')){
      $('span:contains("Add Mailing Address")').text('Remove Mailing Address');
      $('.row-form-wrapper.mailing-div').show();
      $("#person_addresses_attributes_1_zip, #person_addresses_attributes_1_address_1, #person_addresses_attributes_1_city, #dependent_addresses_1_address_1, #dependent_addresses_1_zip,  #dependent_addresses_1_city").each(function() {
        $(this).prop('required', true);
      })
      $("#person_addresses_attributes_0_zip, #person_addresses_attributes_0_address_1, #person_addresses_attributes_0_address_2, #person_addresses_attributes_0_city, #dependent_addresses_0_address_1, #dependent_addresses_0_address_2, #dependent_addresses_0_zip, #dependent_addresses_0_city, #person_addresses_attributes_0_county, #dependent_addresses_0_zip, #dependent_addresses_0_county").each(function() {
        $(this).attr('disabled', true);
      })
      $("#address_info .home-div .selectric-wrapper").hide();
    } else {
      $('.mailing-div').hide();
      $(".mailing-div input[type='text']").val("");
      $(".mailing-div #state_id_mailing").val("");
      $('.mailing-div .label-floatlabel').hide();
      $('span:contains("Remove Mailing Address")').text('Add Mailing Address');
      $("#person_addresses_attributes_1_zip, #person_addresses_attributes_1_address_1, #person_addresses_attributes_1_city, #dependent_addresses_1_address_1, #dependent_addresses_1_zip, #dependent_addresses_1_city").each(function() {
        $(this).prop('required', false);
      })
      $("#person_addresses_attributes_0_zip, #person_addresses_attributes_0_address_1, #person_addresses_attributes_0_address_2, #person_addresses_attributes_0_city, #dependent_addresses_0_address_1, #dependent_addresses_0_address_2, #dependent_addresses_0_zip, #dependent_addresses_0_city, #person_addresses_attributes_0_county, #dependent_addresses_0_zip, #dependent_addresses_0_county").each(function() {
        $(this).attr('disabled', false);
      })
      $("#address_info .home-div .selectric-wrapper").show();
    }
  });
});
