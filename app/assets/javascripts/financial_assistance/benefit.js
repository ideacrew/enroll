function stopEditingBenefit() {
  $('input.benefit-checkbox').prop('disabled', false);
  $('.col-md-2 > .interaction-click-control-continue').removeClass('disabled');
};

function startEditingBenefit() {
  $('input.benefit-checkbox').prop('disabled', true);
  $('.col-md-2 > .interaction-click-control-continue').addClass('disabled');
};

function currentlyEditing() {
  return $('.interaction-click-control-continue').hasClass('disabled');
};

$(document).ready(function() {
  $('input[type="checkbox"]').click(function(e){
    var value = e.target.checked;
    if (value) {
      var newBenefitFormEl = $(this).parents('.benefit-kind').children('.new-benefit-form'),
          benefitListEl = $(this).parents('.benefit-kind').find('.benefits-list');
      newBenefitFormEl.clone(true)
        .removeClass('hidden')
        .appendTo(benefitListEl);
      startEditingBenefit();
      $(newBenefitFormEl).find("#financial_assistance_benefit_start_on").datepicker();
      $(newBenefitFormEl).find("#financial_assistance_benefit_end_on").datepicker();
    } else {
      alert("here");
      // prompt to delete all these benefits
    }
  });

  /* cancel benefit edits */
  $('a.benefit-cancel').click(function(e) {
    e.preventDefault();
    stopEditingBenefit();

    //debugger
    if (!$(this).parents('.benefits-list > div.benefit').length) {
      $(this).parents('.benefit-kind').find('input[type="checkbox"]').prop('checked', false);
    }
    $(this).parents('.new-benefit-form').remove();
  });

/* Condtional Display Enrolled Benefit Questions */
  $("#enrolled-benefit-kinds").addClass('hide');
  $("#enrolled_in_health_coverage_yes").prop('checked', false)
  $("#enrolled_in_health_coverage_no").prop('checked', false)

  $("body").on("change", "#enrolled_in_health_coverage_yes", function(){
    if ($('#enrolled_in_health_coverage_yes').is(':checked')) {
      $("#enrolled-benefit-kinds").removeClass('hide');
    } else{
      $("#enrolled-benefit-kinds").addClass('hide');
    }
  });

  $("body").on("change", "#enrolled_in_health_coverage_no", function(){
    if ($('#enrolled_in_health_coverage_no').is(':checked')) {
      $("#enrolled-benefit-kinds").addClass('hide');
    } else{
      $("#enrolled-benefit-kinds").removeClass('hide');
    }
  });

/* Condtional Display Eligible Benefit Questions */
  $("#eligible-benefit-kinds").addClass('hide');
  $("#eligible_for_health_coverage_yes").prop('checked', false)
  $("#eligible_for_health_coverage_no").prop('checked', false)

  $("body").on("change", "#eligible_for_health_coverage_yes", function(){
    if ($('#eligible_for_health_coverage_yes').is(':checked')) {
      $("#eligible-benefit-kinds").removeClass('hide');
    } else{
      $("#eligible-benefit-kinds").addClass('hide');
    }
  });

  $("body").on("change", "#eligible_for_health_coverage_no", function(){
    if ($('#eligible_for_health_coverage_no').is(':checked')) {
      $("#eligible-benefit-kinds").addClass('hide');
    } else{
      $("#eligible-benefit-kinds").removeClass('hide');
    }
  });

});

