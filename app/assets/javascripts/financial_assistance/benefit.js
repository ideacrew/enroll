function stopEditingBenefit() {
  $('input.benefit-checkbox').prop('disabled', false);
  $('a.benefit-edit').removeClass('disabled');
  // $('a.benefit-delete').removeClass('disabled');
  $('.col-md-2 > .interaction-click-control-continue').removeClass('disabled');
};

function startEditingBenefit() {
  $('input.benefit-checkbox').prop('disabled', true);
  $('a.benefit-edit').addClass('disabled');
  // $('a.benefit-delete').removeClass('disabled');
  $('.col-md-2 > .interaction-click-control-continue').addClass('disabled');
};

function currentlyEditing() {
  return $('.interaction-click-control-continue').hasClass('disabled');
};

function afterDestroyHide(selector_id, kind){
  $(".benefits #"+selector_id+" input[type='checkbox'][value='"+kind+"']").prop('checked', false);
  $(".benefits #"+selector_id+" .add-more-link-"+kind).addClass('hidden');
};

$(document).ready(function() {
  $('input[type="checkbox"]').click(function(e){
    var value = e.target.checked;
    if (value) {
      var newBenefitFormEl = $(this).parents('.benefit-kind').children('.new-benefit-form'),
          benefitListEl = $(this).parents('.benefit-kind').find('.benefits-list');
      if (newBenefitFormEl.find('select').data('selectric')) newBenefitFormEl.find('select').selectric('destroy');
      var clonedForm = newBenefitFormEl.clone(true, true)
        .removeClass('hidden')
        .appendTo(benefitListEl);
      startEditingBenefit();
      $(clonedForm).find('select').selectric();
      $(clonedForm).find(".datepicker-js").datepicker();
    } else {
      // prompt to delete all these benefits
    }
  });

  /* Add more benefits */
  $(document).on('click', "#add_new_insurance_kind", function(e){
      $(this).addClass("hidden");
      var newBenefitFormEl = $(this).closest('.benefit-kind').children('.new-benefit-form'),
        benefitListEl = $(this).closest('.benefit-kind').find('.benefits-list');
      if (newBenefitFormEl.find('select').data('selectric')) newBenefitFormEl.find('select').selectric('destroy');
      var clonedForm = newBenefitFormEl.clone(true, true)
        .removeClass('hidden')
        .appendTo(benefitListEl);
        startEditingBenefit();
      $(clonedForm).find('select').selectric();
      $(clonedForm).find(".datepicker-js").datepicker();
  });

  /* edit existing benefits */
  $('.benefits-list').on('click', 'a.benefit-edit:not(.disabled)', function(e) {
    e.preventDefault();
    var benefitEl = $(this).parents('.benefit');
    benefitEl.find('.benefit-show').addClass('hidden');
    benefitEl.find('.edit-benefit-form').removeClass('hidden');
    startEditingBenefit();

    $(clonedForm).find('select').selectric();
    $(clonedForm).find(".datepicker-js").datepicker();
  });


  /* destroy existing benefits */
  $('.benefits-list').on('click', 'a.benefit-delete:not(.disabled)', function(e) {
    var self = this;
    e.preventDefault();
    $("#destroyBenefit").modal();

    $("#destroyBenefit .modal-cancel-button").click(function(e) {
      $("#destroyBenefit").modal('hide');
    });

    $("#destroyBenefit .modal-continue-button").click(function(e) {
      $("#destroyBenefit").modal('hide');
      $(self).parents('.benefit').remove();

      var url = $(self).parents('.benefit').attr('id').replace('financial_assistance_benefit_', 'benefits/')
      $.ajax({
        type: 'delete',
        url: url
      })
    });
  });

  /* cancel benefit edits */
  $('.benefits-list').on('click', 'a.benefit-cancel', function(e) {
    e.preventDefault();
    stopEditingBenefit();

    var benefitEl = $(this).parents('.benefit');
    if (benefitEl.length) {
      $(this).closest('.benefit-kind').find('a#add_new_insurance_kind').removeClass("hidden");
      benefitEl.find('.benefit-show').removeClass('hidden');
      benefitEl.find('.edit-benefit-form').addClass('hidden');
    } else {
      if (!$(this).parents('.benefits-list').find('div.benefit').length) {
        $(this).parents('.benefit-kind').find('input[type="checkbox"]').prop('checked', false);
        $(this).closest('.benefit-kind').find('a#add_new_insurance_kind').addClass("hidden");
      }else{
        $(this).closest('.benefit-kind').find('a#add_new_insurance_kind').removeClass("hidden");
      }
      $(this).parents('.new-benefit-form').remove();
      $(this).parents('.edit-benefit-form').remove();
    }
  });   

/* Condtional Display Enrolled Benefit Questions */

  if ($("#has_enrolled_health_coverage_no").is(':checked')) $("#enrolled-benefit-kinds").addClass('hide');

  $("body").on("change", "#has_enrolled_health_coverage_yes", function(){
    if ($('#has_enrolled_health_coverage_yes').is(':checked')) {
      $("#enrolled-benefit-kinds").removeClass('hide');
    } else{
      $("#enrolled-benefit-kinds").addClass('hide');
    }
  });

  $("body").on("change", "#has_enrolled_health_coverage_no", function(){
    if ($('#has_enrolled_health_coverage_no').is(':checked')) {
      $("#enrolled-benefit-kinds").addClass('hide');
    } else{
      $("#enrolled-benefit-kinds").removeClass('hide');
    }
  });

/* Condtional Display Eligible Benefit Questions */
  if ($("#has_eligible_health_coverage_no").is(':checked')) $("#eligible-benefit-kinds").addClass('hide');

  $("body").on("change", "#has_eligible_health_coverage_yes", function(){
    if ($('#has_eligible_health_coverage_yes').is(':checked')) {
      $("#eligible-benefit-kinds").removeClass('hide');
    } else{
      $("#eligible-benefit-kinds").addClass('hide');
    }
  });

  $("body").on("change", "#has_eligible_health_coverage_no", function(){
    if ($('#has_eligible_health_coverage_no').is(':checked')) {
      $("#eligible-benefit-kinds").addClass('hide');
    } else{
      $("#eligible-benefit-kinds").removeClass('hide');
    }
  });

});

