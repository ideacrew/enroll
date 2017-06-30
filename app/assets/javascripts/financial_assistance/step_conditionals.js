$(document).ready(function() {

    $.ajax({
      type: "GET",
      data:{},
      url: window.location.href.replace("step", "age_18_to_26"),
      success: function (age) {
        hide_show_foster_care_related_qns(age);
       }
    });

    function hide_show_foster_care_related_qns(age) {
      if ($('#pregnant_yes')){
        if (age == "false"){
          $('#medicaid_pregnency_yes').parents(".row").next().addClass('hide');
          $('#medicaid_pregnency_yes').parents(".row").next().next().addClass('hide');
          $('#medicaid_pregnency_yes').parents(".row").next().next().next().addClass('hide');
          $('#medicaid_pregnency_yes').parents(".row").next().next().next().next().addClass('hide');
        }
        else {
          $('#medicaid_pregnency_yes').parents(".row").next().addClass('hide');
          $('#medicaid_pregnency_yes').parents(".row").next().next().addClass('hide');
          $('#medicaid_pregnency_yes').parents(".row").next().next().next().addClass('hide');
          $('#medicaid_pregnency_yes').parents(".row").next().next().next().next().addClass('hide');
        }
      }
    }

  $('#income_kind').on('selectric-change', function(e){
    if ($(this).val() == 'wages_and_salaries')
      toggle_employer_contact_divs('show'); 
    else
      toggle_employer_contact_divs('hide');
  });

  if ($('#income_kind').val() == 'wages_and_salaries'){
    toggle_employer_contact_divs('show');
  }
  else {
    toggle_employer_contact_divs('hide');
  }


  function toggle_employer_contact_divs(hide_show) {
    if (hide_show == 'hide') {
      $('#income_kind').parents(".row").next().next().addClass('hide');
      $('#income_kind').parents(".row").next().next().next().addClass('hide');
      $('#income_kind').parents(".row").next().next().next().next().addClass('hide');
    }
    else {
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
      $(this).parents(".row").next().addClass('hide');
    }
    else{
      $(this).parents(".row").next().next().removeClass('hide');
    }
  });
  $("body").on("change", "#is_required_to_file_taxes_yes", function(){

    if ($('#is_required_to_file_taxes_yes').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
    }
    else{
      $(this).parents(".row").next().next().addClass('hide');
    }
  });

  $("body").on("change", "#is_claimed_as_tax_dependent_no", function(){
    if ($('#is_claimed_as_tax_dependent_no').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
    }
    else{
      $(this).parents(".row").next().next().removeClass('hide');
    }
  });

  $("body").on("change", "#is_claimed_as_tax_dependent_yes", function(){

    if ($('#is_claimed_as_tax_dependent_yes').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
    }
    else{
      $(this).parents(".row").next().next().addClass('hide');
    }
  });

  $("body").on("click", ".interaction-click-control-next-step", function(e){
        var errorMsgs = [];
        var form = $(this).parents("form");
        var $requiredFieldRows = $(this).parents("form").find(".row:not(.hide):not(:last-child)");
        var totalRequiredCount = $requiredFieldRows.length - 1;  // -1 for the last row..
        var totRadioSelected = $(this).parents("form").find(".row:not(.hide) input[type='radio']:checked").length;
        var isValid = totRadioSelected == totalRequiredCount;
        $requiredFieldRows.each(function(index, element) {
            var $this = $(this);
            if($this.find("input[type='radio']").length && !$this.find("input[type='radio']:checked").length) {
                 errorMsgs.push("PLEASE SELECT * " + $this.find("span").text().replace('*', ''));
            } else {
                $this.find(".alert-error").html("");
            }
        });
        if ($(errorMsgs).length > 0){
            $(".alert-error").text(errorMsgs);
            $(".alert-error").removeClass('hide');
        }
        else{
            $(".alert-error").text("");
            $(".alert-error").addClass('hide');
            $(form).submit();

        }
        return isValid;
    });

  $("body").on("change", "#is_enrolled_no2", function(){
    if ($('#is_enrolled_no2').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
    };
  });

  $("body").on("change", "#is_enrolled_yes2", function(){
    if ($('#is_enrolled_yes2').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
    };
  });

  $("body").on("change", "#is_eligible_no2", function(){
    if ($('#is_eligible_no2').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
      $(this).parents(".row").next().next().addClass('hide');
      toggle_employer_contact_divs_benefit('hide');
    };
  });

  $("body").on("change", "#is_eligible_yes2", function(){
    if ($('#is_eligible_yes2').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $(this).parents(".row").next().next().removeClass('hide');
      toggle_employer_contact_divs_benefit('show');
    };
  });

  $('#benefit_kind').on('selectric-change', function(e){
    if ($(this).val() == 'employer_sponsored_insurance')
      toggle_employer_contact_divs_benefit('show');
    else
      toggle_employer_contact_divs_benefit('hide');
  });

  if( $("#kind_dropdown .label").text() == 'employer_sponsored_insurance'){
    toggle_employer_contact_divs_benefit('show');
  } else {
    toggle_employer_contact_divs_benefit('hide');
  };

  function toggle_employer_contact_divs_benefit(hide_show) {
    if (hide_show == 'show') {
      $('#benefit_kind').parents(".row").next().next().removeClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().removeClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().removeClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().removeClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().next().removeClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().next().next().removeClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().next().next().next().removeClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().next().next().next().next().removeClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().next().next().next().next().next().removeClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().next().next().next().next().next().next().removeClass('hide');
    }
    else {
      $('#benefit_kind').parents(".row").next().next().addClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().addClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().addClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().addClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().next().addClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().next().next().addClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().next().next().next().addClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().next().next().next().next().addClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().next().next().next().next().next().addClass('hide');
      $('#benefit_kind').parents(".row").next().next().next().next().next().next().next().next().next().next().next().addClass('hide');
    }
  }

  // Clear 0 value for Benefit
  if ($("#benefit_kind").val() == 0){
   $("#benefit_kind").val("");
  }

/* Applicant's Tax Info Form Related */
  if($('#is_required_to_file_taxes_no').is(':checked')) {
    $('#is_required_to_file_taxes_no').parents(".row").next().addClass('hide');
  }

  if($('#is_required_to_file_taxes_yes').is(':checked')) {
    $('#is_required_to_file_taxes_yes').parents(".row").next().removeClass('hide');
  }

  if($('#is_claimed_as_tax_dependent_no').is(':checked')) {
    $('#is_claimed_as_tax_dependent_no').parents(".row").next().addClass('hide');
  }

  if($('#is_claimed_as_tax_dependent_yes').is(':checked')) {
    $('#is_claimed_as_tax_dependent_yes').parents(".row").next().removeClass('hide');
  }
/* Applicant's Tax Info Form Related */


/* Applicant's Other Questions Form Related */
  $("body").on("change", "#pregnant_no", function(){
    if ($('#pregnant_no').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
      $(this).parents(".row").next().next().addClass('hide');
      $(this).parents(".row").next().next().next().removeClass('hide');
      $(this).parents(".row").next().next().next().next().removeClass('hide');
    };
  });

  $("body").on("change", "#pregnant_yes", function(){
    if ($('#pregnant_yes').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $(this).parents(".row").next().next().removeClass('hide');
      $(this).parents(".row").next().next().next().addClass('hide');
      $(this).parents(".row").next().next().next().next().addClass('hide');
      $(this).parents(".row").next().next().next().next().next().addClass('hide');
    };
  });

  if($('#pregnant_no').is(':checked')) {
    $('#pregnant_no').parents(".row").next().addClass('hide');
    $('#pregnant_no').parents(".row").next().next().addClass('hide');
    $('#pregnant_no').parents(".row").next().next().next().removeClass('hide');
    $('#pregnant_no').parents(".row").next().next().next().next().removeClass('hide');
  }

  if($('#pregnant_yes').is(':checked')) {
    $('#pregnant_yes').parents(".row").next().removeClass('hide');
    $('#pregnant_yes').parents(".row").next().next().removeClass('hide');
    $('#pregnant_yes').parents(".row").next().next().next().addClass('hide');
    $('#pregnant_yes').parents(".row").next().next().next().next().addClass('hide');
    $('#pregnant_yes').parents(".row").next().next().next().next().next().addClass('hide');
  }

  $("body").on("change", "#is_post_partum_period_yes", function(){
    if ($('#is_post_partum_period_yes').is(':checked')) {
      $(this).parents(".row").next().next().removeClass('hide');
    };
  });

  $("body").on("change", "#is_post_partum_period_no", function(){
    if ($('#is_post_partum_period_no').is(':checked')) {
      $(this).parents(".row").next().next().addClass('hide');
    };
  });

  if($('#is_post_partum_period_yes').is(':checked')) {
    $('#is_post_partum_period_yes').parents(".row").next().next().removeClass('hide');
  }

  if($('#is_post_partum_period_no').is(':checked')) {
    $('#is_post_partum_period_no').parents(".row").next().next().addClass('hide');
  }

  $("body").on("change", "#former_foster_care_no", function(){
    if ($('#former_foster_care_no').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
      $(this).parents(".row").next().next().addClass('hide');
      $(this).parents(".row").next().next().next().addClass('hide');
    };
  });

  $("body").on("change", "#former_foster_care_yes", function(){
    if ($('#former_foster_care_yes').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $(this).parents(".row").next().next().removeClass('hide');
      $(this).parents(".row").next().next().next().removeClass('hide');
    };
  });

  if($('#former_foster_care_no').is(':checked')) {
    $('#former_foster_care_no').parents(".row").next().addClass('hide');
    $('#former_foster_care_no').parents(".row").next().next().addClass('hide');
    $('#former_foster_care_no').parents(".row").next().next().next().addClass('hide');
  }

  if($('#former_foster_care_yes').is(':checked')) {
    $('#former_foster_care_yes').parents(".row").next().removeClass('hide');
    $('#former_foster_care_yes').parents(".row").next().next().removeClass('hide');
    $('#former_foster_care_yes').parents(".row").next().next().next().removeClass('hide');
  }

  $("body").on("change", "#student_no", function(){
    if ($('#student_no').is(':checked')) {
      $(this).parents(".row").next().addClass('hide');
      $(this).parents(".row").next().next().addClass('hide');
      $(this).parents(".row").next().next().next().addClass('hide');
    };
  });

  $("body").on("change", "#student_yes", function(){
    if ($('#student_yes').is(':checked')) {
      $(this).parents(".row").next().removeClass('hide');
      $(this).parents(".row").next().next().removeClass('hide');
      $(this).parents(".row").next().next().next().removeClass('hide');
    };
  });

  if($('#student_no').is(':checked')) {
    $('#student_no').parents(".row").next().addClass('hide');
    $('#student_no').parents(".row").next().next().addClass('hide');
    $('#student_no').parents(".row").next().next().next().addClass('hide');
  }

  if($('#student_yes').is(':checked')) {
    $('#student_yes').parents(".row").next().removeClass('hide');
    $('#student_yes').parents(".row").next().next().removeClass('hide');
    $('#student_yes').parents(".row").next().next().next().removeClass('hide');
  }
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
  /* Preference Application Form Related */

});
