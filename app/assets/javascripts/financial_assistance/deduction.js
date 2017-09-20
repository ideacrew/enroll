function stopEditingDeduction() {
  $('input.deduction-checkbox').prop('disabled', false);
  $('.col-md-2 > .interaction-click-control-continue').removeClass('disabled');
};

function startEditingDeduction() {
  $('input.deduction-checkbox').prop('disabled', true);
  $('.col-md-2 > .interaction-click-control-continue').addClass('disabled');
};

function currentlyEditing() {
  return $('.interaction-click-control-continue').hasClass('disabled');
};

$(document).ready(function() {
  $('input[type="checkbox"]').click(function(e){
    var value = e.target.checked;
    if (value) {
      var newDeductionFormEl = $(this).parents('.deduction-kind').children('.new-deduction-form'),
          deductionListEl = $(this).parents('.deduction-kind').find('.deductions-list');
      newDeductionFormEl.clone(true)
        .removeClass('hidden')
        .appendTo(deductionListEl);
      startEditingDeduction();
      $(newDeductionFormEl).find("#financial_assistance_deduction_start_on").datepicker();
      $(newDeductionFormEl).find("#financial_assistance_deduction_end_on").datepicker();
    } else {
      // prompt to delete all these dedcutions
    }
  });

  /* cancel deduction edits */
  $('a.deduction-cancel').click(function(e) {
    e.preventDefault();
    stopEditingDeduction();

    //debugger
    if (!$(this).parents('.deductions-list > div.deduction').length) {
      $(this).parents('.deduction-kind').find('input[type="checkbox"]').prop('checked', false);
    }
    $(this).parents('.new-deduction-form').remove();
  });

});

