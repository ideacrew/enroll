function isApplyingCoverage(target){

fields = "input[name='" + target + "[is_applying_coverage]']"
    $("#employer-coverage-msg").hide();
    $("#ssn-coverage-msg").hide();
  if($(fields).length > 0){
    addEventOnNoSsn(target);
    addEventOnSsn(target);
    if($(fields).not(":checked").val() == "true"){
      $("#consumer_fields_sets").hide();
      $("#employer-coverage-msg").show();
      if($("input[name='" + target + "[ssn]']").val() == '' && !$("input[name='" + target + "[no_ssn]']").is(":checked")){
        $("#ssn-coverage-msg").show();
      }

    }
    $(fields).change(function () {
      if($(fields).not(":checked").val() == "true"){
        $("#consumer_fields_sets").hide();
        $("#employer-coverage-msg").show();
        if($("input[name='" + target + "[ssn]']").val() == '' && !$("input[name='" + target + "[no_ssn]']").is(":checked")){
          $("#ssn-coverage-msg").show();
        }
      }else{
        $("#consumer_fields_sets").show();
        $("#employer-coverage-msg").hide();
        $("#ssn-coverage-msg").hide();
      }
    });
  }
}

function addEventOnNoSsn(target){
  $("input[name='" + target + "[no_ssn]']").change(function() {
    if($(this).is(":checked")) {
       $("#ssn-coverage-msg").hide();
    }else if($("input[name='" + target + "[ssn]']").val() == '' && $("input[name='" + target + "[is_applying_coverage]']").not(":checked").val() == "true"){
        $("#ssn-coverage-msg").show();
    }
  });
}

function addEventOnSsn(target){
  $("input[name='" + target + "[ssn]']").keyup(function() {
    if($(this).val() != '') {
       $("#ssn-coverage-msg").hide();
    }else if( !$("input[name='" + target + "[no_ssn]']").is(":checked") && $("input[name='" + target + "[is_applying_coverage]']").not(":checked").val() == "true"){
        $("#ssn-coverage-msg").show();
    }
  });
}

function applyListenersFor(target) {
    // target is person or dependent
    $("input[name='" + target + "[us_citizen]']").change(function() {
        $('#vlp_documents_container').hide();
        $('#vlp_documents_container .vlp_doc_area').html("");
        $("input[name='" + target + "[naturalized_citizen]']").attr('checked', false);
        $("input[name='" + target + "[eligible_immigration_status]']").attr('checked', false);
        if ($(this).val() == 'true') {
            $('#naturalized_citizen_container').show();
            $('#eligible_immigration_status_container').hide();
            $("#" + target + "_naturalized_citizen_true").attr('required');
            $("#" + target + "_naturalized_citizen_false").attr('required');
        } else {
            $('#naturalized_citizen_container').hide();
            $('#eligible_immigration_status_container').show();
            $("#" + target + "_naturalized_citizen_true").removeAttr('required');
            $("#" + target + "_naturalized_citizen_false").removeAttr('required');
        }
    });

    $("input[name='" + target + "[naturalized_citizen]']").change(function() {
        if ($(this).val() == 'true') {
            $('#vlp_documents_container').show();
            $('#naturalization_doc_type_select').show();
            $('#immigration_doc_type_select').hide();
        } else {
            $('#vlp_documents_container').hide();
            $('#naturalization_doc_type_select').hide();
            $('#immigration_doc_type_select').hide();
            $('#vlp_documents_container .vlp_doc_area').html("");
        }
    });

    $("input[name='" + target + "[eligible_immigration_status]']").change(function() {
        if ($(this).val() == 'true') {
            $('#vlp_documents_container').show();
            $('#naturalization_doc_type_select').hide();
            $('#immigration_doc_type_select').show();
        } else {
            $('#vlp_documents_container').hide();
            $('#naturalization_doc_type_select').hide();
            $('#immigration_doc_type_select').hide();
            $('#vlp_documents_container .vlp_doc_area').html("");
        }
    });

    $("input[name='" + target + "[indian_tribe_member]']").change(function() {
        if ($(this).val() == 'true') {
            $('#tribal_container').show();
        } else {
            $('#tribal_container').hide();
            $('#tribal_id').val("");
        }
    });
}

function showOnly(selected) {
    if (selected == '' || selected == undefined) {
        return false;
    }
    var vlp_doc_map = {
        "Certificate of Citizenship": "citizenship_cert_container",
        "Naturalization Certificate": "naturalization_cert_container",
        "I-327 (Reentry Permit)": "immigration_i_327_fields_container",
        "I-551 (Permanent Resident Card)": "immigration_i_551_fields_container",
        "I-571 (Refugee Travel Document)": "immigration_i_571_fields_container",
        "I-766 (Employment Authorization Card)": "immigration_i_766_fields_container",
        "Machine Readable Immigrant Visa (with Temporary I-551 Language)": "machine_readable_immigrant_visa_fields_container",
        "Temporary I-551 Stamp (on passport or I-94)": "immigration_temporary_i_551_stamp_fields_container",
        "I-94 (Arrival/Departure Record)": "immigration_i_94_fields_container",
        "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport": "immigration_i_94_2_fields_container",
        "Unexpired Foreign Passport": "immigration_unexpired_foreign_passport_fields_container",
        "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)": "immigration_temporary_i_20_stamp_fields_container",
        "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)": "immigration_DS_2019_fields_container",
        "Other (With Alien Number)": "immigration_other_with_alien_number_fields_container",
        "Other (With I-94 Number)": "immigration_other_with_i94_fields_container"
    };
    var vlp_doc_target = vlp_doc_map[selected];
    $(".vlp_doc_area").html("<span>waiting...</span>");
    var target_id = $('input#vlp_doc_target_id').val();
    var target_type = $('input#vlp_doc_target_type').val();
    $.ajax({
        type: "get",
        url: "/insured/consumer_role/immigration_document_options",
        dataType: 'script',
        data: {
            'target_id': target_id,
            'target_type': target_type,
            'vlp_doc_target': vlp_doc_target,
            'vlp_doc_subject': selected
        }
    });
}

function applyListeners() {
    if ($("form.edit_person").length > 0) {
        applyListenersFor("person");
    } else if ($("form.new_dependent, form.edit_dependent").length > 0) {
        applyListenersFor("dependent");
    }

    $("#naturalization_doc_type").change(function() {
        showOnly($(this).val());
    });

    $("#immigration_doc_type").change(function() {
        showOnly($(this).val());
    });
}

function validationForIndianTribeMember() {
    if ($('#indian_tribe_area').length == 0) {
        return false;
    };
    $('.close').click(function() {
        $('#tribal_id_alert').hide()
    });
    $('form.edit_person, form.new_dependent, form.edit_dependent').submit(function(e) {
        if (!$("input#indian_tribe_member_yes").is(':checked') && !$("input#indian_tribe_member_no").is(':checked')) {
            alert("Please select the option for 'Are you a member of an American Indian or Alaskan Native tribe?'");
            e.preventDefault && e.preventDefault();
            return false;
        };

        // for tribal_id
        var tribal_val = $('#tribal_id').val();
        if ($("input#indian_tribe_member_yes").is(':checked') && (tribal_val == "undefined" || tribal_val == '')) {
            $('#tribal_id_alert').show();
            e.preventDefault && e.preventDefault();
            return false;
        }
    });
}

var PersonValidations = (function(window, undefined) {

  function manageRequiredValidations(this_obj) {
    hidden_requireds = $('[required]').not(":visible");
    $('[required]').not(":visible").removeProp('required');
    this_obj.closest('div').find('button[type="submit"]').trigger('click');
  }

    function checkRequiredFields(this_obj) {
        PersonValidations.checkConsumerInputRequiredFields(this_obj);
        PersonValidations.manageRequiredValidations(this_obj);
        DependentsValidationFields.check_continue_button();
    }

    function validationForPhysicallyDisabled(e) {
      if ($('input[name="person[is_applying_coverage]"]').length > 0 && $('input[name="person[is_applying_coverage]"]').not(":checked").val() == "true"){
        return true;
      }
      if ($('input[name="person[is_physically_disabled]"]').not(":checked").length == 2) {
        alert('Please provide an answer for question: Does this person have a disability?');
        PersonValidations.restoreRequiredAttributes(e);
      }
    }

    function restoreRequiredAttributes(e) {
        e.preventDefault && e.preventDefault();
        hidden_requireds.each(function(index) {
            $(this).prop('required', true);
        });
    }


    function checkConsumerInputRequiredFields(e){
      var checking_fields = {
          'person[us_citizen]': 'Are you a US Citizen or US National?',
          'person[naturalized_citizen]': 'Are you a naturalized citizen?',
          'person[eligible_immigration_status]': 'Do you have eligible immigration status?',
          'person[indian_tribe_member]': 'Are you a member of an American Indian or Alaskan Native tribe?',
          'person[is_incarcerated]': 'Are you currently incarcerated?',
          'dependent[us_citizen]': 'Are you a US Citizen or US National?',
          'dependent[naturalized_citizen]': 'Are you a naturalized citizen?',
          'dependent[eligible_immigration_status]': 'Do you have eligible immigration status?',
          'dependent[indian_tribe_member]': 'Are you a member of an American Indian or Alaskan Native tribe?',
          'dependent[is_incarcerated]': 'Are you currently incarcerated?'
      };

      $.each(checking_fields, function(key, value){
          if ($("#"+key.split('[').pop().split("]").shift()+"_container").is(':visible') && ($("input[name='"+key+"']").length > 1)) {
              if (($("input[name='"+key+"']")).not(":checked").length == 2) {
                  DependentsValidationFields.disable_continue();
                  alert('Please provide an answer for question:' + value );
                  PersonValidations.restoreRequiredAttributes(e);
              }
          }
      });
    }

    function validationForVlpDocuments(e) {
        if ($('#vlp_documents_container').is(':visible')) {
            var doc_errors = []

            if ($("#immigration_doc_type").is(":visible")) {
              var doc_type = $("#immigration_doc_type").val();
            } else {
              var doc_type = $("#naturalization_doc_type").val();
            };

            $('.vlp_doc_area input.doc_fields').each(function() {
                if ($(this).attr('placeholder') == 'Citizenship Number') {
                    if ($(this).val().length < 1) {
                        alert('Please fill in your information for ' + $(this).attr('placeholder') + '.');
                        PersonValidations.restoreRequiredAttributes(e);
                    } else {
                      alphaNumericCheck($(this), [6, 12], 'Citizenship Number');
                    }
                }
                if ($(this).attr('placeholder') == 'Alien Number') {
                    if ($(this).val().length < 1) {
                        alert('Please fill in your information for ' + $(this).attr('placeholder') + '.');
                        PersonValidations.restoreRequiredAttributes(e);
                    } else {
                      integerCheck($(this), 9, 'Alien Number');
                    }
                }
                if ($(this).attr('placeholder') == 'Card Number') {
                    if ($(this).val().length < 1) {
                        alert('Please fill in your information for ' + $(this).attr('placeholder') + '.');
                        PersonValidations.restoreRequiredAttributes(e);
                    } else {
                      integerCheck($(this), 13, 'Card Number');  
                    }
                }
                if ($(this).attr('placeholder') == 'Naturalization Number') {
                    if ($(this).val().length < 1) {
                        alert('Please fill in your information for ' + $(this).attr('placeholder') + '.');
                        PersonValidations.restoreRequiredAttributes(e);
                    } else {
                      alphaNumericCheck($(this), [6, 12], 'Naturalization Number');
                    }
                }
                if ($(this).attr('placeholder') == 'SEVIS ID') {
                  if ($(this).val().length < 1) {
                    alert('Please fill in your information for ' + $(this).attr('placeholder') + '.');
                    PersonValidations.restoreRequiredAttributes(e);
        
                  } else {
                    integerCheck($(this), 10, 'SEVIS ID');
                  }
                }
        
                if ($(this).attr('placeholder') == 'Passport Number') {
                  if ($(this).val().length < 1) {
                    alert('Please fill in your information for ' + $(this).attr('placeholder') + '.');
                    PersonValidations.restoreRequiredAttributes(e);
        
                  } else {
                    alphaNumericCheck($(this), [6, 12], 'Passport Number');
                  }
                }
        
                if ($(this).attr('placeholder') == 'I 94 Number') {
                  if ($(this).val().length < 1) {
                    alert('Please fill in your information for ' + $(this).attr('placeholder') + '.');
                    PersonValidations.restoreRequiredAttributes(e);
        
                  } else {
                    integerCheck($(this), 11, 'I 94 Number');
                  }
                }
        
                if ($(this).attr('placeholder') == 'Visa number') {
                  if ($(this).val().length < 1) {
                    alert('Please fill in your information for ' + $(this).attr('placeholder') + '.');
                    PersonValidations.restoreRequiredAttributes(e);
        
                  } else {
                    alphaNumericCheck($(this), [8, 8], 'Visa Number');
                  }
                }
        
                if ($(this).attr('placeholder') == 'I-766 Expiration Date') {
                    if ($(this).val().length != 10) {
                        alert('Please fill in your information for ' + $(this).attr('placeholder') + ' with a MM/DD/YYYY format.');
                        PersonValidations.restoreRequiredAttributes(e);

                    } else {}
                }
//        if ($(this).attr('placeholder') == 'I-94 Expiration Date') {
//          if ($(this).val().length != 10) {
//            alert('Please fill in your information for ' + $(this).attr('placeholder') + ' with a MM/DD/YYYY format.');
//            PersonValidations.restoreRequiredAttributes(e);
//
//          } else {}
//        }
      });

      function integerCheck(elem, digit, placeholder) {
        var number = elem.val()
        var alien_number = new RegExp('^\\d{'+digit+'\}$');
        if(!(alien_number.test(number))) {
          if (!(number.length == digit)) {
            doc_errors.push(doc_type + ": " + placeholder + " has wrong length (should be " + digit +" characters)")
          } else {
            doc_errors.push(doc_type + ": " + placeholder + " should be in requested format (Only integers)")
          }
        }
      }

      function alphaNumericCheck(element, limits, placeholder) {
        var number = element.val()
        var min = limits[0]
        var max = limits[1]
        var naturalization_number = new RegExp('^[a-z0-9]{'+min+'\,'+max+'\}$');
        if(!(naturalization_number.test(number))) {
          if (!(number.length >= min && number.length <= max)) {
            if (min == max) {
              doc_errors.push(doc_type + ": " + placeholder + " has wrong length (should be " + min +" characters)")
            } else {
              doc_errors.push(doc_type + ": " + placeholder + " has wrong length (minimum " + min + " and maximum " + max + " characters)")
            }
          } else {
            doc_errors.push(doc_type + ": " + placeholder + " should be in requested format (should NOT contain any special characters)")
          }
        }
      };

      if(doc_errors.length) {
        $('html,body').animate({scrollTop: 0});
        $(".alert.alert-alert").remove();

        var error_str = "<h4> The following requires your attention:</h4>"
        var ul = '<p><ul>';

        for (i in doc_errors){
          ul+='<li>' + doc_errors[i] + '</li>';
        }
        ul+='</ul>';

        error_str += ul

        if($(".my-account-page").length) {
          $(".my-account-page").prepend("<div class='alert alert-alert'>" + error_str);
        } else {
          if ($("#personal_info").length) {
            $("#personal_info").prepend("<div class='alert alert-alert'>" + error_str);
          } else {
            $(".house").prepend("<div class='alert alert-alert'>" + error_str);
          };
        };
        e.preventDefault();
        e.stopPropagation();
      } else {
        $(".alert.alert-alert").remove();
      }
    } else {
      $(".alert.alert-alert").remove();
    }
  }    

    // explicitly return public methods when this object is instantiated
    return {
        manageRequiredValidations: manageRequiredValidations,
        validationForVlpDocuments: validationForVlpDocuments,
        restoreRequiredAttributes: restoreRequiredAttributes,
        checkRequiredFields: checkRequiredFields,
        validationForPhysicallyDisabled: validationForPhysicallyDisabled,
        checkConsumerInputRequiredFields: checkConsumerInputRequiredFields
    };

})(window);

$(document).ready(function() {
    applyListeners();
    validationForIndianTribeMember();

    $('html').on('submit', 'form.edit_person, form.new_dependent, form.edit_dependent', function(e) {
        PersonValidations.checkConsumerInputRequiredFields(e);
        PersonValidations.validationForVlpDocuments(e);
        PersonValidations.validationForPhysicallyDisabled(e);
    });

  isApplyingCoverage("person");
});