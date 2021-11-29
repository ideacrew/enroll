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
    if(`EnrollRegistry.feature_enabled?(:ridp_h139) && Rails.env.production? && !(ENV['ENROLL_REVIEW_ENVIRONMENT'] == 'true')`) {
      var path = "/insured/fdsh_ridp_verifications/new";
    } else {
      var path = "/insured/interactive_identity_verifications/new";
    }
    $(document).on("click", ".interaction-choice-control-value-agreement-agree", function(){
        $(".interaction-click-control-continue").attr("href", path);
        $('.aut_cons_text').parents('.row-form-wrapper').addClass('hide');
    });
    $(document).on("click", ".interaction-choice-control-value-agreement-disagree", function(){
        $(".interaction-click-control-continue").attr("href", "/insured/consumer_role/upload_ridp_document");
        $('.aut_cons_text').parents('.row-form-wrapper').removeClass('hide');
    });
});
