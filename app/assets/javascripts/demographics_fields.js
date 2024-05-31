function isApplyingCoverage(target) {
  fields = "input[name='" + target + "[is_applying_coverage]']";
  $('#employer-coverage-msg').hide();
  $('#ssn-coverage-msg').hide();
  if ($(fields).length > 0) {
    addEventOnNoSsn(target);
    addEventOnSsn(target);
    if ($(fields).not(':checked').val() == 'true') {
      $('.consumer_fields_for_applying_coverage').hide();
      $('#employer-coverage-msg').show();
      if ($("input[name='" + target + "[ssn]']").val() == '' && !$("input[name='" + target + "[no_ssn]']").is(':checked')) {
        $('#ssn-coverage-msg').show();
      }
    }
    $(fields).change(function () {
      if ($(fields).not(':checked').val() == 'true') {
        $('.consumer_fields_for_applying_coverage').hide();
        $('#employer-coverage-msg').show();
        if ($("input[name='" + target + "[ssn]']").val() == '' && !$("input[name='" + target + "[no_ssn]']").is(':checked')) {
          $('#ssn-coverage-msg').show();
        }
      } else {
        $('.consumer_fields_for_applying_coverage').show();
        $('#employer-coverage-msg').hide();
        $('#ssn-coverage-msg').hide();
      }
    });
  }
}

function addEventOnNoSsn(target) {
  $("input[name='" + target + "[no_ssn]']").change(function () {
    if ($(this).is(':checked')) {
      $('#ssn-coverage-msg').hide();
    } else if ($("input[name='" + target + "[ssn]']").val() == '' && $("input[name='" + target + "[is_applying_coverage]']").not(':checked').val() == 'true') {
      $('#ssn-coverage-msg').show();
    }
  });
}

function addEventOnSsn(target) {
  $("input[name='" + target + "[ssn]']").keyup(function () {
    if ($(this).val() != '') {
      $('#ssn-coverage-msg').hide();
    } else if (
      !$("input[name='" + target + "[no_ssn]']").is(':checked') &&
      $("input[name='" + target + "[is_applying_coverage]']")
        .not(':checked')
        .val() == 'true'
    ) {
      $('#ssn-coverage-msg').show();
    }
  });
}

function enableContinueButton() {
  var continueButton =  $('.interaction-click-control-continue.hidden');
  if (continueButton.is(':disabled')) {
    continueButton.prop('disabled', false);
  }
}

function applyListenersFor(target) {
  // target is person or dependent
  $("input[name='" + target + "[us_citizen]']").change(function () {
    enableContinueButton();
    $('#vlp_documents_container').hide();
    $('#vlp_documents_container .vlp_doc_area').html('');
    $("input[name='" + target + "[naturalized_citizen]']").prop(
      'checked',
      false
    );
    $("input[name='" + target + "[eligible_immigration_status]']").prop(
      'checked',
      false
    );
    if ($(this).val() == 'true') {
      $('#naturalized_citizen_container').show();
      $('#immigration_status_container').hide();
      $('#' + target + '_naturalized_citizen_true').prop('required');
      $('#' + target + '_naturalized_citizen_false').prop('required');
    } else {
      $('#naturalized_citizen_container').hide();
      $('#immigration_status_container').show();
      $('#' + target + '_naturalized_citizen_true').removeAttr('required');
      $('#' + target + '_naturalized_citizen_false').removeAttr('required');
    }
  });

  $("input[name='" + target + "[naturalized_citizen]']").change(function () {
    enableContinueButton();
    var selected_doc_type = $('#naturalization_doc_type').val();
    if ($(this).val() == 'true') {
      $('#vlp_documents_container').show();
      $('#naturalization_doc_type_select').show();
      $('#immigration_doc_type_select').hide();
      showOnly(selected_doc_type);
    } else {
      $('#vlp_documents_container').hide();
      $('#naturalization_doc_type_select').hide();
      $('#immigration_doc_type_select').hide();
      $('#vlp_documents_container .vlp_doc_area').html('');
    }
  });

  $("input[name='" + target + "[eligible_immigration_status]']").change(
    function () {
      enableContinueButton();
      var selected_doc_type = $('#immigration_doc_type').val();
      if ($(this).val() == 'true' && this.checked) {
        $('#vlp_documents_container').show();
        $('#naturalization_doc_type_select').hide();
        $('#immigration_doc_type_select').show();
        showOnly(selected_doc_type);
      } else {
        $('#vlp_documents_container').hide();
        $('#naturalization_doc_type_select').hide();
        $('#immigration_doc_type_select').hide();
        $('#vlp_documents_container .vlp_doc_area').html('');
      }
    }
  );

  //start tribe option controls
  $("input[name='" + target + "[indian_tribe_member]']").change(function() {
    if (this.value === 'true') {
      $('.tribal-container').removeClass('hide');
    } else {
      $('.tribal-container').addClass('hide');
    }
  });

  // tribal-state change - select from options
  $('select#tribal-state').on("change", function() {
    enableContinueButton();
    var enroll_state_abbr = $('#enroll_state_abbr').val();
    var is_indian_alaskan_tribe_details_enabled = ($('#is_indian_alaskan_tribe_details_enabled').val() === 'true');

    if (is_indian_alaskan_tribe_details_enabled) {
      var is_featured_tribes_selection_enabled = ($('#is_featured_tribes_selection_enabled').val() === 'true');
      var tribe_codes_array = $('.tribe_codes:checked').map(function() {
        return $(this).val();
      }).get();
      var tribal_name_container_show_on_select = (typeof tribe_codes_array != 'undefined' && tribe_codes_array.includes("OT"));

      if (is_featured_tribes_selection_enabled && this.value == enroll_state_abbr) {
        $('.featured-tribe-container').removeClass('hide');
        if (tribal_name_container_show_on_select) {
          $('.tribal-name-container').removeClass('hide');
        } else {
          $('#tribal-name').val("");
          $('.tribal-name-container').addClass('hide');
        }
      } else {
        $('.tribe_codes:checked').removeAttr('checked');
        $('.tribal-name-container').removeClass('hide');
        $('.featured-tribe-container').addClass('hide');
      }
    }
  });

  $("input#" + target + "_tribe_codes_ot").change(function() {
    if (this.checked){
      $('.tribal-name-container').removeClass('hide');
    } else {
      $('.tribal-name-container').addClass('hide');
    }
  });
  //end tribe option controls

  $('input[name="person[is_incarcerated]"]').change(function () {
    enableContinueButton();
  })

  $('input[name="person[tribal_id]"]').change(function () {
    enableContinueButton();
  })

  $('input[name="person[tribal_name]"]').change(function () {
    enableContinueButton();
  })

  $('.mobile-phone-number').change(function() {
    enableContinueButton();
  })

  $('.tribe_codes').change(function() {
    enableContinueButton();
  })

  $('input[name="person[indian_tribe_member]"]').change(function() {
    enableContinueButton();
  })
}

function showOnly(selected) {
  if (selected == '' || selected == undefined) {
    return false;
  }
  var vlp_doc_map = {
    'Certificate of Citizenship': 'citizenship_cert_container',
    'Naturalization Certificate': 'naturalization_cert_container',
    'I-327 (Reentry Permit)': 'immigration_i_327_fields_container',
    'I-551 (Permanent Resident Card)': 'immigration_i_551_fields_container',
    'I-571 (Refugee Travel Document)': 'immigration_i_571_fields_container',
    'I-766 (Employment Authorization Card)':
      'immigration_i_766_fields_container',
    'Machine Readable Immigrant Visa (with Temporary I-551 Language)':
      'machine_readable_immigrant_visa_fields_container',
    'Temporary I-551 Stamp (on passport or I-94)':
      'immigration_temporary_i_551_stamp_fields_container',
    'I-94 (Arrival/Departure Record)': 'immigration_i_94_fields_container',
    'I-94 (Arrival/Departure Record) in Unexpired Foreign Passport':
      'immigration_i_94_2_fields_container',
    'Unexpired Foreign Passport':
      'immigration_unexpired_foreign_passport_fields_container',
    'I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)':
      'immigration_temporary_i_20_stamp_fields_container',
    'DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)':
      'immigration_DS_2019_fields_container',
    'Other (With Alien Number)':
      'immigration_other_with_alien_number_fields_container',
    'Other (With I-94 Number)': 'immigration_other_with_i94_fields_container',
  };
  var vlp_doc_target = vlp_doc_map[selected];
  $('.vlp_doc_area').html('<span>waiting...</span>');
  var target_id = $('input#vlp_doc_target_id').val();
  var target_type = $('input#vlp_doc_target_type').val();
  $.ajax({
    type: 'get',
    url: '/insured/consumer_role/immigration_document_options',
    dataType: 'script',
    data: {
      target_id: target_id,
      target_type: target_type,
      vlp_doc_target: vlp_doc_target,
      vlp_doc_subject: selected,
    },
  });
}

function applyListeners() {
  if ($('form.edit_person').length > 0) {
    applyListenersFor('person');
  } else if ($('form.new_dependent, form.edit_dependent').length > 0) {
    applyListenersFor('dependent');
  }

  $('#naturalization_doc_type').change(function () {
    showOnly($(this).val());
  });

  $('#immigration_doc_type').change(function () {
    showOnly($(this).val());
  });
}

var PersonValidations = (function (window, undefined) {
  function manageRequiredValidations(this_obj) {
    $('[required]').not(':visible').removeAttr('required');
    this_obj.closest('div').find('button[type="submit"]').trigger('click');
    this_obj.closest('div').find('.dependent-disable').prop('disabled', true);
  }

  function restoreRequiredAttributes(e) {
    e.preventDefault && e.preventDefault();
    hidden_requireds.each(function (index) {
      $(this).prop('required', true);
    });
  }

  function validationForUsCitizenOrUsNational(e) {
    if (
      $('input[name="person[is_applying_coverage]"]').length > 0 &&
      $('input[name="person[is_applying_coverage]"]').not(':checked').val() ==
        'true'
    ) {
      return true;
    }
    if ($('input[name="person[us_citizen]"]').not(':checked').length == 2) {
      alert(
        'Please provide an answer for question: Is this person a US Citizen or US National?'
      );
      PersonValidations.restoreRequiredAttributes(e);
    }
  }

  function validationForIndianTribeMember(e) {
    if ($('#indian_tribe_area').length == 0){
      return false;
    }

    $('.close').click(function() {
      $('#tribal-id-alert').addClass('hide');
      $('#tribal-state-alert').addClass('hide');
      $('#tribal-name-alert').addClass('hide');
    });

    if ($('input[name="person[is_applying_coverage]"]').length > 0
    && $('input[name="person[is_applying_coverage]"]').not(":checked").val() == "true"){
      return true;
    }

    var tribe_member_yes = $("input#indian_tribe_member_yes").is(':checked');
    var tribe_member_no = $("input#indian_tribe_member_no").is(':checked');
    var tribe_member_visible = $(".no_coverage_tribe_details").is(':visible')

    if (!tribe_member_yes && !tribe_member_no && tribe_member_visible){
      alert("Please select the option for 'Are you a member of an American Indian or Alaska Native Tribe?'");
      PersonValidations.restoreRequiredAttributes(e);
    };

    if (tribe_member_no){
      $('#tribal-state').val("");
      $('input#tribal-name').val("");
      $('#tribal-id').val("");
      $('.tribe_codes:checked').removeAttr('checked');
    }

    if (tribe_member_yes){
      if ($('#tribal-state').length > 0 && $('#tribal-state').val() == ""){
        $('#tribal-state-alert').show();
        PersonValidations.restoreRequiredAttributes(e);
      }

      if ($('.featured_tribes_selection').length > 0 && $('#tribal-state').val() == $('#enroll_state_abbr').val()){
        var tribe_codes_array = $('.tribe_codes:checked').map(function(){ return $(this).val(); }).get();
        if (tribe_codes_array.length < 1) {
          alert("At least one tribe must be selected.");
          PersonValidations.restoreRequiredAttributes(e);
        }

        if (tribe_codes_array.includes("OT") && $('input#tribal-name').val() == ""){
            alert("Please provide an answer for 'Other' tribe name.");
            PersonValidations.restoreRequiredAttributes(e);
        }

        if (!tribe_codes_array.includes("OT")){
          $('input#tribal-name').val("");
        }
      }
      else if ($('input#tribal-name').val() == ""){
          $('#tribal-name-alert').show();
          PersonValidations.restoreRequiredAttributes(e);
      }

      if ($('#tribal-id').length > 0 && $('#tribal-id').val() == ""){
          $('#tribal-id-alert').show();
          PersonValidations.restoreRequiredAttributes(e);
      }
    }
  }

  function validationForIncarcerated(e) {
    if (
      $('input[name="person[is_applying_coverage]"]').length > 0 &&
      $('input[name="person[is_applying_coverage]"]').not(':checked').val() ==
        'true'
    ) {
      return true;
    }
    if (
      $('input[name="person[is_incarcerated]"]').not(':checked').length == 2
    ) {
      alert(
        'Please provide an answer for question: Is this person currently incarcerated?'
      );
      PersonValidations.restoreRequiredAttributes(e);
    }
  }

  function validationForTobaccoUser(e) {
    if (
      $('input[name="person[is_applying_coverage]"]').length > 0 &&
      $('input[name="person[is_applying_coverage]"]').not(':checked').val() ==
        'true'
    ) {
      return true;
    }
    if (
      !$('#tobacco_user_container').hasClass('hidden_field') &&
      $('input[name="person[is_tobacco_user]"]').not(':checked').length == 2
    ) {
      alert(
        'Please provide an answer for question: Is this person a tobacco user?'
      );
      PersonValidations.restoreRequiredAttributes(e);
    }
  }

  function validationForNaturalizedCitizen(e) {
    if (
      $('input[name="person[is_applying_coverage]"]').length > 0 &&
      $('input[name="person[is_applying_coverage]"]').not(':checked').val() ==
        'true'
    ) {
      return true;
    }
    if (
      $('#naturalized_citizen_container').is(':visible') &&
      $('input[name="person[naturalized_citizen]"]').not(':checked').length == 2
    ) {
      alert(
        'Please provide an answer for question: Is this person a naturalized or derived citizen?'
      );
      PersonValidations.restoreRequiredAttributes(e);
    }
  }

  function validationForEligibleImmigrationStatuses(e) {
    if (
      $('#immigration_status_container').is(':visible') &&
      $('input[name="person[eligible_immigration_status]"]').not(':checked')
        .length == 2 &&
      !$('#immigration-checkbox').is(':visible')
    ) {
      alert(
        'Please provide an answer for question: Do you have eligible immigration status?'
      );
      PersonValidations.restoreRequiredAttributes(e);
    }
  }

  function validationForPersonOrDependent() {
    const immigration_field =
      document.getElementById('immigration_doc_type').value == '';
    if (!document.getElementById('dependent_ul') && immigration_field) {
      return (
        document.getElementById('person_us_citizen_false').checked ||
        document.getElementById('person_naturalized_citizen_true').checked
      );
    } else if (immigration_field) {
      return (
        document.getElementById('dependent_us_citizen_false').checked ||
        document.getElementById('dependent_naturalized_citizen_true').checked
      );
    }
  }

  function validationForVlpDocuments(e) {
    if (validationForPersonOrDependent()) {
      $('#showWarning').removeClass('hidden');
    }
    if ($('#vlp_documents_container').is(':visible')) {
      $('.vlp_doc_area input.doc_fields').each(function () {
        if ($(this).attr('placeholder') == 'Certificate Number') {
          if ($(this).val().length < 1) {
            if ($(this).hasClass('required')) {
              alert(
                'Please fill in your information for ' +
                  $(this).attr('placeholder') +
                  '.'
              );
              PersonValidations.restoreRequiredAttributes(e);
            } else {
              $('#showWarning').removeClass('hidden');
            }
          } else {
          }
        }
        if (
          $('#immigration_doc_type').val() == 'Naturalization Certificate' ||
          $('#immigration_doc_type').val() == 'Certificate of Citizenship'
        ) {
        } else {
          if ($(this).attr('placeholder') == 'Alien Number') {
            if ($(this).val().length < 1) {
              if ($(this).hasClass('required')) {
                alert(
                  'Please fill in your information for ' +
                    $(this).attr('placeholder') +
                    '.'
                );
                PersonValidations.restoreRequiredAttributes(e);
              } else {
                $('#showWarning').removeClass('hidden');
              }
            } else {
            }
          }
        }

        if ($(this).attr('placeholder') == 'Document Description') {
          if ($(this).val().length < 1) {
            if ($(this).hasClass('required')) {
              alert(
                'Please fill in your information for ' +
                  $(this).attr('placeholder') +
                  '.'
              );
              PersonValidations.restoreRequiredAttributes(e);
            } else {
              $('#showWarning').removeClass('hidden');
            }
          }
        }
        if ($(this).attr('placeholder') == 'Card Number') {
          if ($(this).val().length < 1) {
            if ($(this).hasClass('required')) {
              alert(
                'Please fill in your information for ' +
                  $(this).attr('placeholder') +
                  '.'
              );
              PersonValidations.restoreRequiredAttributes(e);
            } else {
              $('#showWarning').removeClass('hidden');
            }
          }
        }
        if ($(this).attr('placeholder') == 'Naturalization Number') {
          if ($(this).val().length < 1) {
            if ($(this).hasClass('required')) {
              alert(
                'Please fill in your information for ' +
                  $(this).attr('placeholder') +
                  '.'
              );
              PersonValidations.restoreRequiredAttributes(e);
            } else {
              $('#showWarning').removeClass('hidden');
            }
          }
        }
        if (
          $('#immigration_doc_type').val() ==
            'I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)' ||
          $('#immigration_doc_type').val() ==
            'DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)' ||
          $('#immigration_doc_type').val() ==
            'Temporary I-551 Stamp (on passport or I-94)' ||
          $('#immigration_doc_type').val() == 'Other (With Alien Number)' ||
          $('#immigration_doc_type').val() == 'Other (With I-94 Number)'
        ) {
        } else {
          if ($(this).attr('placeholder') == 'Passport Number') {
            if ($(this).val().length < 1) {
              if ($(this).hasClass('required')) {
                alert(
                  'Please fill in your information for ' +
                    $(this).attr('placeholder') +
                    '.'
                );
                PersonValidations.restoreRequiredAttributes(e);
              } else {
                $('#showWarning').removeClass('hidden');
              }
            }
          }
        }
        if ($(this).attr('placeholder') == 'I-766 Expiration Date') {
          if ($(this).val().length != 10) {
            if ($(this).hasClass('required')) {
              alert(
                'Please fill in your information for ' +
                  $(this).attr('placeholder') +
                  ' with a MM/DD/YYYY format.'
              );
              PersonValidations.restoreRequiredAttributes(e);
            } else {
              $('#showWarning').removeClass('hidden');
            }
          }
        }
        //        if ($(this).attr('placeholder') == 'I-94 Expiration Date') {
        //          if ($(this).val().length != 10) {
        //            alert('Please fill in your information for ' + $(this).attr('placeholder') + ' with a MM/DD/YYYY format.');
        //            PersonValidations.restoreRequiredAttributes(e);
        //
        //          } else {}
        //        }
        if (
          $('#immigration_doc_type').val() == 'Unexpired Foreign Passport' ||
          $('#immigration_doc_type').val() ==
            'I-94 (Arrival/Departure Record) in Unexpired Foreign Passport'
        ) {
          if ($(this).attr('placeholder') == 'Passport Expiration Date') {
            if ($(this).val().length != 10) {
              if ($(this).hasClass('required')) {
                alert(
                  'Please fill in your information for ' +
                    $(this).attr('placeholder') +
                    ' with a MM/DD/YYYY format.'
                );
                PersonValidations.restoreRequiredAttributes(e);
              } else {
                $('#showWarning').removeClass('hidden');
              }
            }
          }
        }
        if (
          $('#immigration_doc_type').val() == 'Unexpired Foreign Passport' ||
          $('#immigration_doc_type').val() ==
            'I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)' ||
          $('#immigration_doc_type').val() ==
            'DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)'
        ) {
        } else {
          if ($(this).attr('placeholder') == 'I 94 Number') {
            if ($(this).val().length < 1) {
              if ($(this).hasClass('required')) {
                alert(
                  'Please fill in your information for ' +
                    $(this).attr('placeholder') +
                    '.'
                );
                PersonValidations.restoreRequiredAttributes(e);
              } else {
                $('#showWarning').removeClass('hidden');
              }
            }
          }
        }

        if (
          $('#immigration_doc_type').val() ==
            'I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)' ||
          $('#immigration_doc_type').val() ==
            'DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)'
        ) {
          if ($(this).attr('placeholder') == 'SEVIS ID') {
            if ($(this).val().length < 1) {
              if ($(this).hasClass('required')) {
                alert(
                  'Please fill in your information for ' +
                    $(this).attr('placeholder') +
                    '.'
                );
                PersonValidations.restoreRequiredAttributes(e);
              } else {
                $('#showWarning').removeClass('hidden');
              }
            }
          }
        } else {
        }
      });
    }
  }

  // client specific feature for ME, validates that a contact method is selected
  function validationForContactMethod(e) {
    if ($('.contact-method').length) {
      var isChecked = false;
      $('.contact-method input').each(function (i, el) {
        if ($(el).prop('checked')) {
          isChecked = true;
        }});
      if (isChecked == false) {
        var alertMsg = 'Warning: You must select at least one contact method.'
        if($('.contact-method').hasClass('flag-enabled')){
          alertMsg += ' An additional method must be checked if selecting Text.';
        }
        alert(alertMsg);
        PersonValidations.restoreRequiredAttributes(e);
      }

      if ($('.interaction-choice-control-value-person-consumer-role-attributes-contact-method-email').prop('checked')) {
        if (!$('#person_emails_attributes_0_address').val()) {
          alert('You must enter an email address to receive notices and updates by email.');
          PersonValidations.restoreRequiredAttributes(e);
        }
      }

      if ($('.interaction-choice-control-value-person-consumer-role-attributes-contact-method-text').prop('checked')) {
        if (document.querySelector('.mobile-phone-number').value.length < 1) {
          alert('You must enter a mobile phone number to receive notices and updates by text.');
          PersonValidations.restoreRequiredAttributes(e);
        }
        if ($('.contact-method input:checked').length <= 1 && $('.contact-method').hasClass('flag-enabled')){
          alert('An additional contact method is required if only Text is selected.');
          PersonValidations.restoreRequiredAttributes(e);
        }
      }
    }
  }

  // explicitly return public methods when this object is instantiated
  return {
    manageRequiredValidations: manageRequiredValidations,
    validationForUsCitizenOrUsNational: validationForUsCitizenOrUsNational,
    validationForNaturalizedCitizen: validationForNaturalizedCitizen,
    validationForEligibleImmigrationStatuses: validationForEligibleImmigrationStatuses,
    validationForVlpDocuments: validationForVlpDocuments,
    validationForIncarcerated: validationForIncarcerated,
    validationForTobaccoUser: validationForTobaccoUser,
    validationForContactMethod: validationForContactMethod,
    validationForIndianTribeMember: validationForIndianTribeMember,
    restoreRequiredAttributes: restoreRequiredAttributes,
  };
})(window);

$(document).on('turbolinks:load', function () {
  demographicValidations();
});

function demographicValidations() {
  applyListeners();

  $('form.edit_person, form.new_dependent, form.edit_dependent').submit(
    function (e) {
      PersonValidations.validationForUsCitizenOrUsNational(e);
      PersonValidations.validationForNaturalizedCitizen(e);
      PersonValidations.validationForEligibleImmigrationStatuses(e);
      PersonValidations.validationForIndianTribeMember(e);
      PersonValidations.validationForIncarcerated(e);
      PersonValidations.validationForTobaccoUser(e);
      PersonValidations.validationForVlpDocuments(e);
      PersonValidations.validationForContactMethod(e);
      if ($('#showWarning').length && !$('#showWarning').hasClass('hidden') && !$('#showWarning').hasClass('shown')) {
        $('#showWarning').addClass('shown');
        e.preventDefault();
        return false;
      }
    });

  isApplyingCoverage('person');
}
