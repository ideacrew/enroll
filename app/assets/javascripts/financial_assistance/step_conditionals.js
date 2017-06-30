$(document).ready(function() {

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

  /* Benefit Form Related */

  $('#benefit_insurance_kind').on('selectric-change', function(e){
    if ($(this).val() == 'employer_sponsored_insurance') {
      toggle_employer_contact_divs_benefit('show');
    }
    else {
      toggle_employer_contact_divs_benefit('hide');
    }
  });

  /* This is to show/hide ESI fields on Page Load. Will show ESI related
   * fields if InsuranceKind is selected as 'employer_sponsored_insurance'
   * when page loads (possible on a page reload due to validation error) */

  var selectedVal = $('#benefit_insurance_kind').val();
  if (selectedVal == 'employer_sponsored_insurance') {
    setTimeout(function() {
      toggle_employer_contact_divs_benefit('show');
    },300);
  }
  else {
    setTimeout(function() {
      toggle_employer_contact_divs_benefit('hide');
    },300);
  };

  function toggle_employer_contact_divs_benefit(hide_show) {
    if (hide_show == 'show') {
      $('#benefit_insurance_kind').parents(".row").next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().next().removeClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().next().next().removeClass('hide');
    }
    else {
      $('#benefit_insurance_kind').parents(".row").next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().next().addClass('hide');
      $('#benefit_insurance_kind').parents(".row").next().next().next().next().next().next().next().next().next().next().addClass('hide');
    }
  }
  /* Benefit Form Related */

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
