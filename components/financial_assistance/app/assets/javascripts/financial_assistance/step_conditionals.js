document.addEventListener("turbolinks:load", function() {
  $('.step-tabs, .interaction-click-control-my-household').on('click', function(e) {
    //Leave without saving for all side nav items - this gathers all items
    $('.btn.btn-primary').click(function() {
        window.location.href = e.target.href;
      });
  });

  /* attestations */
  $('#living_outside_yes, #living_outside_no').off('change')
  $('#living_outside_yes, #living_outside_no').on('change', function(e) {
    if ($('#living_outside_yes').is(':checked')) {
      $('#application_attestation_terms').attr('required', true);
    } else {
      $('#application_attestation_terms').removeAttr('required');
    }
  });

  if ($('#medicaid_pregnancy_yes').length) {
    $.ajax({
      type: "GET",
      data:{},
      url: window.location.href.replace(/other_questions/, "age_of_applicant"),
      success: function (age) {
        hide_show_foster_care_related_qns(age);
      }
    });
  }

  // To hide/show the foster care related questions based on the age_of_applicant.
  function hide_show_foster_care_related_qns(age) {
    if (age >= 18 && age < 26){
      $('#is_former_foster_care_yes').parents('.row-form-wrapper').removeClass('hide');
    } else {
      $('#is_former_foster_care_yes').parents('.row-form-wrapper').addClass('hide');
      $('#foster_care_us_state, #age_left_foster_care, #had_medicaid_during_foster_care_yes').parents('.row-form-wrapper').addClass('hide');
      $('#is_former_foster_care_yes, #is_former_foster_care_no').prop('required', false);
      $('#had_medicaid_during_foster_care_yes, #had_medicaid_during_foster_care_no').prop('required', false);
    }
  }

  function hide_show_person_flling_jointly_question(){
    $.ajax({
      type: "GET",
      data:{},
      url: window.location.href.replace(/tax_info/, 'applicant_is_eligible_for_joint_filing'),
      success: function (has_spouse_relationship) {
        if(has_spouse_relationship == 'true'){
          $('#is_joint_tax_filing_no').parents('.is_joint_tax_filing').removeClass('hide');
        }
      }
    });
  }

  $('#income_kind').on('selectric-change', function(e){
    if ($(this).val() == 'wages_and_salaries')
      toggle_employer_contact_divs('show');
    else
      toggle_employer_contact_divs('hide');
  });

  if ($('#income_kind').val() == 'wages_and_salaries'){
    toggle_employer_contact_divs('show');
  } else {
    toggle_employer_contact_divs('hide');
  }


  function toggle_employer_contact_divs(hide_show) {
    if (hide_show == 'hide') {
      $('#income_kind').parents(".row").next().next().addClass('hide');
      $('#income_kind').parents(".row").next().next().next().addClass('hide');
      $('#income_kind').parents(".row").next().next().next().next().addClass('hide');
    } else {
      $('#income_kind').parents(".row").next().next().removeClass('hide');
      $('#income_kind').parents(".row").next().next().next().removeClass('hide');
      $('#income_kind').parents(".row").next().next().next().next().removeClass('hide');
    }
  }

  // Clear 0 value for Income
  if ($("#income_amount").val() == 0){
   $("#income_amount").val("");
  }

  $("body").on("change", "#is_required_to_file_taxes_no", function(){
    if ($('#is_required_to_file_taxes_no').is(':checked')) {
      $('#is_joint_tax_filing_no').parents('.is_joint_tax_filing').addClass('hide');
      $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('checked', false)
      $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('required', false);
      $('.filing-as-head-of-household').first().addClass('hide');
    } else{
      $('.is_claimed_as_tax_dependent').removeClass('hide');
    }
  });

  $("body").on("change", "#is_required_to_file_taxes_yes", function(){
    if ($('#is_required_to_file_taxes_yes').is(':checked')) {
      hide_show_person_flling_jointly_question();
      if($('#is_joint_tax_filing_no').is(':checked')) {
        $('.filing-as-head-of-household').first().removeClass('hide');
        $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('required', true);
      }
    } else{
      $('.is_claimed_as_tax_dependent').addClass('hide');
    }
  });

  $("body").on("change", "#is_joint_tax_filing_no", function(){
    if ($('#is_joint_tax_filing_no').is(':checked')) {
      $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('required', true);
      $('.filing-as-head-of-household').first().removeClass('hide');
    }
  });

  $("body").on("change", "#is_joint_tax_filing_yes", function(){
    if ($('#is_joint_tax_filing_yes').is(':checked')) {
      $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('checked', false)
      $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('required', false);
      $('.filing-as-head-of-household').first().addClass('hide');
    }
  });

  $('.claimed_as_tax_dependent_by').addClass('hide');

  $("body").on("change", "#is_claimed_as_tax_dependent_no", function(){
    if ($('#is_claimed_as_tax_dependent_no').is(':checked')) {
      $('.claimed_as_tax_dependent_by').addClass('hide');
    } else{
      $(this).parents(".row").next().next().removeClass('hide');
    }
  });

  $("body").on("change", "#is_claimed_as_tax_dependent_yes", function(){
    if ($('#is_claimed_as_tax_dependent_yes').is(':checked')) {
      $('.claimed_as_tax_dependent_by').removeClass('hide');
    } else{
      $(this).parents(".row").next().next().addClass('hide');
    }
  });

  /* employer phone & zip validations */
  $('#employer_phone_full_phone_number').on('keyup keydown keypress', function (e) {
    var key = e.which || e.keyCode || e.charCode;
    $(this).attr('maxlength', '10');
    return (key == 8 ||
      key == 9 ||
      key == 46 ||
      (key >= 37 && key <= 40) ||
      (key >= 48 && key <= 57) ||
      (key >= 96 && key <= 105) );
  })

  .on('focus', function () {
    $(this).val($(this).val().replace(/\W+/g, ''));
  })

  .on('blur', function () {
    $(this).val($(this).val().replace(/^(\d{3})(\d{3})(\d{4})+$/, "($1) $2-$3"));
  });

  $("#employer_address_zip").mask("99999");
  /* employer phone & zip validations */


  /* Toggle Show/Hide of  dates row when eligible/ enrolled types are selected */
  $("#is_eligible, #is_enrolled").on('change', function() {
    if ($('#is_eligible').is(':checked')) {
      $('#is_eligible').parents(".row").next().addClass('hide');
      $('#is_eligible').parents(".row").next().removeClass('show');
    } else {
      $('#is_eligible').parents(".row").next().addClass('show');
      $('#is_eligible').parents(".row").next().removeClass('hide');
    }
  });

  /* Submit Application Form Related */

  $('#attestation_terms').addClass('hide');

  $("body").on("change", "#living_outside_no", function(){
    if ($('#living_outside_no').is(':checked')) {
      $("#attestation_terms").addClass('hide');
    };
  });

  $("body").on("change", "#living_outside_yes", function(){
    if ($('#living_outside_yes').is(':checked')) {
      $("#attestation_terms").removeClass('hide');
    };
  });

  // On Load, hide by default if checked no
  if($('#living_outside_no').is(':checked')) {
    $("#attestation_terms").addClass('hide');
  }

  if($('#living_outside_yes').is(':checked')) {
    $("#attestation_terms").removeClass('hide');
  }
  /* Submit Application Form Related */


  /* Preference Application Form Related */

  // On Load, hide by default if checked
  if ($('#eligibility_easier_yes').is(':checked')) {
    $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
    $('#eligibility_easier_yes').parents(".row").next().next().addClass('hide');
  };

  $("body").on("change", "#eligibility_easier_yes", function(){
    if ($('#eligibility_easier_yes').is(':checked')) {
      $('#renewal_years').addClass('hide');
    };
  });

  $("body").on("change", "#eligibility_easier_no", function(){
    if ($('#eligibility_easier_no').is(':checked')) {
      $('#renewal_years').removeClass('hide');
    };
  });

  if($('#eligibility_easier_yes').is(':checked')) {
    $('#renewal_years').addClass('hide');
  }

  if($('#eligibility_easier_no').is(':checked')) {
    $('#renewal_years').removeClass('hide');
  }

/* Applicant's Tax Info Form Related */

  $('#is_joint_tax_filing_yes').parents('.is_joint_tax_filing').addClass('hide');

  if($('#is_required_to_file_taxes_no').is(':checked')) {
    $('#is_joint_tax_filing_yes').parents('.is_joint_tax_filing').addClass('hide');
    $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('checked', false)
    $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('required', false);
    $('.filing-as-head-of-household').first().addClass('hide');
  }

  if($('#is_required_to_file_taxes_yes').is(':checked')) {
    hide_show_person_flling_jointly_question();
    if($('#is_joint_tax_filing_no').is(':checked')) {
      $('.filing-as-head-of-household').first().removeClass('hide');
      $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('required', true);
    } else {
      $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('checked', false)
      $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('required', false);
      $('.filing-as-head-of-household').first().addClass('hide');
    }
  }

  if(!$('#is_required_to_file_taxes_no, #is_required_to_file_taxes_yes').is(':checked')) {
    $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('checked', false)
    $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').prop('required', false);
    $('.filing-as-head-of-household').first().addClass('hide');
  }

  if($('#is_claimed_as_tax_dependent_no').is(':checked')) {
    $('.claimed_as_tax_dependent_by').addClass('hide');
  }

  if($('#is_claimed_as_tax_dependent_yes').is(':checked')) {
    $('.claimed_as_tax_dependent_by').removeClass('hide');
  }

  $("#is_required_to_file_taxes_yes, #is_required_to_file_taxes_no, #is_claimed_as_tax_dependent_yes, #is_claimed_as_tax_dependent_no, #is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no, #is_joint_tax_filing_no, #is_joint_tax_filing_yes").on('change', function() {
    var taxInfoPage = document.querySelector("[data-cuke='tax_info_header']");
    if( (typeof(taxInfoPage) != 'undefined' && taxInfoPage != null)
        && ($('#is_required_to_file_taxes_yes, #is_required_to_file_taxes_no').is(':checked') && $('#is_claimed_as_tax_dependent_yes, #is_claimed_as_tax_dependent_no').is(':checked'))
        && ($('.hide.filing-as-head-of-household').length > 0
        || (((($('.filing-as-head-of-household').length > 0) && $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').is(':checked')) || ($('.filing-as-head-of-household').length == 0) || $('#is_required_to_file_taxes_no').is(':checked') || $('#is_joint_tax_filing_yes').is(':checked'))))){
     $('input[type="submit"]#btn-continue').prop('disabled', false)
     //
   }
 });
/* Applicant's Tax Info Form Related */

$(document).ready(function(){
  var taxInfoPage = document.querySelector("[data-cuke='tax_info_header']");
  if( (typeof(taxInfoPage) != 'undefined' && taxInfoPage != null)
      && ($('#is_required_to_file_taxes_yes, #is_required_to_file_taxes_no').is(':checked') && $('#is_claimed_as_tax_dependent_yes, #is_claimed_as_tax_dependent_no').is(':checked'))
      && ($('.hide.filing-as-head-of-household').length > 0
      || ((($('.filing-as-head-of-household').length > 0) && $('#is_filing_as_head_of_household_yes, #is_filing_as_head_of_household_no').is(':checked')) || $('.filing-as-head-of-household').length == 0))){
    $('input[type="submit"]#btn-continue').prop('disabled', false)
 }
})

/* Applicant's Other Questions Form Related */

  if ($('#is_ssn_applied_yes').is(':checked')) {
    $('#no_ssn_reason').parents('.row-form-wrapper').addClass('hide');
  } else {
    $('#no_ssn_reason').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#is_ssn_applied_yes", function(){
    if ($('#is_ssn_applied_yes').is(':checked')) {
      $('#no_ssn_reason').parents('.row-form-wrapper').addClass('hide');
    };
  });

  if ($('#is_ssn_applied_no').is(':checked')) {
    $('#no_ssn_reason').parents('.row-form-wrapper').removeClass('hide');
  } else {
    $('#no_ssn_reason').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#is_ssn_applied_no", function(){
    if ($('#is_ssn_applied_no').is(':checked')) {
      $('#no_ssn_reason').parents('.row-form-wrapper').removeClass('hide');
    };
  });

  $('#applicant_pregnancy_end_on').parents('.row-form-wrapper').addClass('hide');

  $("body").on("change", "#is_pregnant_yes", function(){
    if ($('#is_pregnant_yes').is(':checked')) {
      $('#children_expected_count, #applicant_pregnancy_due_on').parents('.row-form-wrapper').removeClass('hide');
      if (!disable_selectric) {
        $('#children_expected_count').selectric();
      }
      $('#is_post_partum_period_yes, #applicant_pregnancy_end_on').parents('.row-form-wrapper').addClass('hide');
      $('#medicaid_pregnancy_yes').parents('.row-form-wrapper').addClass('hide');
    };
  });

  if($('#is_pregnant_yes').is(':checked')) {
    $('#children_expected_count, #applicant_pregnancy_due_on').parents('.row-form-wrapper').removeClass('hide');
    $('#medicaid_pregnancy_yes').parents('.row-form-wrapper').addClass('hide');
  } else {
    $('#children_expected_count, #applicant_pregnancy_due_on').parents('.row-form-wrapper').addClass('hide');
    $('#medicaid_pregnancy_yes').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#is_pregnant_no", function(){
    if ($('#is_pregnant_no').is(':checked')) {
      $('#is_post_partum_period_yes').parents('.row-form-wrapper').removeClass('hide');
      $('#is_post_partum_period_yes, #is_post_partum_period_no').attr('checked', false);
      $('#children_expected_count, #applicant_pregnancy_due_on').parents('.row-form-wrapper').addClass('hide');
      $('#medicaid_pregnancy_yes').parents('.row-form-wrapper').addClass('hide');
    };
  });

  if($('#is_pregnant_no').is(':checked')) {
    $('#is_post_partum_period_yes').parents('.row-form-wrapper').removeClass('hide');
    $('#medicaid_pregnancy_yes').parents('.row-form-wrapper').addClass('hide');
  } else {
    $('#is_post_partum_period_yes').parents('.row-form-wrapper').addClass('hide');
    $('#medicaid_pregnancy_yes').parents('.row-form-wrapper').addClass('hide');
  }

  if($('#is_post_partum_period_yes').is(':checked')) {
    $('#medicaid_pregnancy_yes, #applicant_pregnancy_end_on').parents('.row-form-wrapper').removeClass('hide');
  }

  $("body").on("change", "#is_post_partum_period_yes", function(){
    if ($('#is_post_partum_period_yes').is(':checked')) {
      $('#medicaid_pregnancy_yes, #applicant_pregnancy_end_on').parents('.row-form-wrapper').removeClass('hide');
    };
  });

  if($('#is_post_partum_period_no').is(':checked')) {
    $('#medicaid_pregnancy_yes, #applicant_pregnancy_end_on').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#is_post_partum_period_no", function(){
    if ($('#is_post_partum_period_no').is(':checked')) {
      $('#medicaid_pregnancy_yes, #applicant_pregnancy_end_on').parents('.row-form-wrapper').addClass('hide');
    };
  });


  $("body").on("change", "#is_former_foster_care_no", function(){
    if ($('#is_former_foster_care_no').is(':checked')) {
      $('#foster_care_us_state, #age_left_foster_care, #had_medicaid_during_foster_care_yes').parents('.row-form-wrapper').addClass('hide');
      $('#had_medicaid_during_foster_care_yes, #had_medicaid_during_foster_care_no').prop('required', false);
    };
  });

  $("body").on("change", "#is_former_foster_care_yes", function(){
    if ($('#is_former_foster_care_yes').is(':checked')) {
      $('#foster_care_us_state, #age_left_foster_care, #had_medicaid_during_foster_care_yes').parents('.row-form-wrapper').removeClass('hide');
    };
  });

  if($('#is_former_foster_care_yes').is(':checked')) {
    $('#foster_care_us_state, #age_left_foster_care, #had_medicaid_during_foster_care_yes').parents('.row-form-wrapper').removeClass('hide');
  } else {
    $('#foster_care_us_state, #age_left_foster_care, #had_medicaid_during_foster_care_yes').parents('.row-form-wrapper').addClass('hide');
    $('#had_medicaid_during_foster_care_yes, #had_medicaid_during_foster_care_no').prop('required', false);
  }

  $("body").on("change", "#is_student_no", function(){
    if ($('#is_student_no').is(':checked')) {
      $('#student_kind, #applicant_student_status_end_on, #student_school_kind').parents('.row-form-wrapper').addClass('hide');
    };
  });

  $("body").on("change", "#is_student_yes", function(){
    if ($('#is_student_yes').is(':checked')) {
      $('#student_kind, #applicant_student_status_end_on, #student_school_kind').parents('.row-form-wrapper').removeClass('hide');
    };
  });

  if($('#is_student_yes').is(':checked')) {
    $('#student_kind, #applicant_student_status_end_on, #student_school_kind').parents('.row-form-wrapper').removeClass('hide');
  } else {
    $('#student_kind, #applicant_student_status_end_on, #student_school_kind').parents('.row-form-wrapper').addClass('hide');
  }

  //start primary caregiver controls
  $("body").on("change", "#is_primary_caregiver_no", function(){
    if ($('#is_primary_caregiver_no').is(':checked')) {
      $('#is_primary_caregiver_for').parents('.row-form-wrapper').addClass('hide');
    };
  });

  $("body").on("change", "#is_primary_caregiver_yes", function(){
    if ($('#is_primary_caregiver_yes').is(':checked')) {
      $('#is_primary_caregiver_for').parents('.row-form-wrapper').removeClass('hide');
    };
  });

  if($('#is_primary_caregiver_yes').is(':checked')) {
    $('#is_primary_caregiver_for').parents('.row-form-wrapper').removeClass('hide');
  } else {
    $('#is_primary_caregiver_for').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#applicant_is_primary_caregiver_for_none", function(){
    if ($('#applicant_is_primary_caregiver_for_none').is(':checked')) {
      $('.interaction-choice-control-value-is-primary-caregiver-for').prop( "checked", false );
    }
  });

  $("body").on("change", "#is_primary_caregiver_for", function(){
    if ($('#is_primary_caregiver_for:checked').length > 0) {
      $('#applicant_is_primary_caregiver_for_none').prop( "checked", false );
    }
  });
  //end primary caregiver controls

  if($('#is_veteran_or_active_military_yes').is(':checked')) {
    $('#is_vets_spouse_or_child_yes').parents('.row-form-wrapper').addClass('hide');
  } else {
    $('#is_vets_spouse_or_child_yes').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#is_veteran_or_active_military_yes", function(){
    if ($('#is_veteran_or_active_military_yes').is(':checked')) {
      $('#is_vets_spouse_or_child_yes').parents('.row-form-wrapper').addClass('hide');
    };
  });

  if($('#is_veteran_or_active_military_no').is(':checked')) {
    $('#is_vets_spouse_or_child_yes').parents('.row-form-wrapper').removeClass('hide');
  } else {
    $('#is_vets_spouse_or_child_yes').parents('.row-form-wrapper').addClass('hide');
  }

  $("body").on("change", "#is_veteran_or_active_military_no", function(){
    if ($('#is_veteran_or_active_military_no').is(':checked')) {
      $('#is_vets_spouse_or_child_yes').parents('.row-form-wrapper').removeClass('hide');
    };
  });

/* Applicant's Other Questions Form Related */

  /* Submit Application Form Related */
  $("body").on("change", "#living_outside_no", function(){
    if ($('#living_outside_no').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
      $(this).parents(".row").next().next().addClass('hide');
    };
  });

  $("body").on("change", "#living_outside_yes", function(){
    if ($('#living_outside_yes').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $(this).parents(".row").next().next().removeClass('hide');
    };
  });

  // On Load, hide by default if checked no
  if($('#living_outside_no').is(':checked')) {
    $('#living_outside_no').parents(".row").next().addClass('hide');
    $('#living_outside_no').parents(".row").next().next().addClass('hide');
  }

  if($('#living_outside_yes').is(':checked')) {
    $('#living_outside_yes').parents(".row").next().removeClass('hide');
  }
  /* Submit Application Form Related */

  /* Preference Application Form Related */

  // On Load, hide by default if checked
  if ($('#eligibility_easier_yes').is(':checked')) {
      $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
      $('#eligibility_easier_yes').parents(".row").next().next().addClass('hide');
  };

  $("body").on("change", "#eligibility_easier_yes", function(){
    if ($('#eligibility_easier_yes').is(':checked')) {
      $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
      $('#eligibility_easier_yes').parents(".row").next().next().addClass('hide');
    };
  });

  $("body").on("change", "#eligibility_easier_no", function(){
    if ($('#eligibility_easier_no').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $(this).parents(".row").next().next().removeClass('hide');
    };
  });

  if($('#eligibility_easier_yes').is(':checked')) {
    $('#eligibility_easier_yes').parents(".row").next().addClass('hide');
  }

  if($('#eligibility_easier_no').is(':checked')) {
    $('#eligibility_easier_no').parents(".row").next().removeClass('hide');
  }

  $("#mailed_yes, #mailed_no").on('change', function() {
    if( $('#mailed_yes, #mailed_no').is(':checked')){
      $('.interaction-click-control-continue').prop('disabled', false);
     }
  });

  /* Preference Application Form Related */

  /* enable or disable submit application button by checkboxes & electronic siganture (first/last name match)*/
  function enable_submit_button() {
    first_name_thank_you = $("#first_name_thank_you").val() ? $("#first_name_thank_you").val().toString().toLowerCase().trim() : '';
    last_name_thank_you = $("#last_name_thank_you").val() ? $("#last_name_thank_you").val().toString().toLowerCase().trim() : '';
    subscriber_first_name = $("#subscriber_first_name").val();
    subscriber_last_name = $("#subscriber_last_name").val();
    living_outside_no = $('#living_outside_no').is(':checked');
    living_outside_yes = $('#living_outside_yes').is(':checked');
    medicare_review_box = $('#application_medicaid_terms').is(':checked');
    medicaid_insurance_box = $('#application_medicaid_insurance_collection_terms').is(':checked');
    report_change_box = $('#application_report_change_terms').is(':checked');
    medicaid_terms_box = $('#application_submission_terms').is(':checked');
    attestation_terms = $('#application_attestation_terms').is(':checked');

    boxes_checked = medicare_review_box && medicaid_insurance_box && report_change_box && medicaid_terms_box
    living_outside_checked = living_outside_no || (living_outside_yes && attestation_terms)
    signature_valid = (first_name_thank_you == subscriber_first_name) && (last_name_thank_you == subscriber_last_name)
    checks_complete = boxes_checked && living_outside_checked && signature_valid
    if(checks_complete){
      $('.interaction-click-control-submit-application').removeClass('disabled');
    } else {
      $('.interaction-click-control-submit-application').addClass('disabled');
    }
  }

  $(window).load(function() {
    $('.interaction-click-control-submit-application').addClass('disabled');
    enable_submit_button();
  });

  $(document).on('change click blur keyup',  function() {
    enable_submit_button();
  });

 /* enable or disable submit application button by checkboxes & electronic siganture (first/last name match)*/
});
