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

$(document).on('ready', function(){
    $(".interaction-choice-control-value-agreement-agree").prop("checked", true);
    $('.aut_cons_text').parents('.row-form-wrapper').addClass('hide');
    $(".interaction-choice-control-value-agreement-agree").click(function(){
        $(".interaction-click-control-continue").attr("href", "/insured/interactive_identity_verifications/new");
        $('.aut_cons_text').parents('.row-form-wrapper').addClass('hide');
    });
    $(".interaction-choice-control-value-agreement-disagree").click(function(){
        $(".interaction-click-control-continue").attr("href", "/insured/consumer_role/upload_ridp_document");
        $('.aut_cons_text').parents('.row-form-wrapper').removeClass('hide');
    });
});
