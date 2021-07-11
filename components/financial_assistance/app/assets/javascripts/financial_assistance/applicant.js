$(document).on('change', '#applicant_same_with_primary', function(){
  var target = $(this).parents('#applicant-address').find('#applicant-home-address-area');
  if ($(this).is(':checked')) {
    $(target).hide();
    $(this).parents('#applicant-address').find('#home-info').hide();
    $(target).find("#address_info .address_required").removeAttr('required');
  } else {
    $(target).show();
    $(this).parents('#applicant-address').find('#home-info').show();
    if (!$(target).find("#applicant_no_dc_address").is(':checked')){
      $(target).find("#address_info .address_required").attr('required', true);
    };
  }
});

$(document).on('change', "#applicant_is_homeless", function(){
// $('#dependent_is_homeless').change(function() {
  if ($(this).prop('checked')){
    $('span:contains("Add Mailing Address")').text('Remove Mailing Address');
    $('.row-form-wrapper.mailing-div').show();
    $("#applicant_addresses_attributes_1_zip, #applicant_addresses_attributes_1_address_1, #applicant_addresses_attributes_1_city").each(function() {
      $(this).prop('required', true);
    })
    $("#applicant_addresses_attributes_0_zip, #applicant_addresses_attributes_0_address_1, #applicant_addresses_attributes_0_address_2, #applicant_addresses_attributes_0_city, #applicant_addresses_attributes_0_county").each(function() {
      $(this).attr('disabled', true);
    })
    $("#address_info .home-div .selectric-wrapper").hide();
  } else {
    $('span:contains("Remove Mailing Address")').text('Add Mailing Address');
    $('.mailing-div').hide();
    $(".mailing-div input[type='text']").val("");
    $(".mailing-div #state_id_mailing").val("")
    $('.mailing-div .label-floatlabel').hide();
    $("#applicant_addresses_attributes_1_zip, #applicant_addresses_attributes_1_address_1, #applicant_addresses_attributes_1_city").each(function() {
      $(this).prop('required', false);
    })
    $("#applicant_addresses_attributes_0_zip, #applicant_addresses_attributes_0_address_1, #applicant_addresses_attributes_0_address_2, #applicant_addresses_attributes_0_city, #applicant_addresses_attributes_0_county").each(function() {
      $(this).attr('disabled', false);
    })
    $("#address_info .home-div .selectric-wrapper").show();
  }
});
