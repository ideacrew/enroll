function stopEditingDeduction() {
  $('input.deduction-checkbox').prop('disabled', false);
  $('a.deduciton-edit').removeClass('disabled');
  $('.col-md-2 > .interaction-click-control-continue').removeClass('disabled');
};

function startEditingDeduction() {
  $('input.deduction-checkbox').prop('disabled', true);
  $('a.deduction-edit').addClass('disabled');
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
      if (newDeductionFormEl.find('select').data('selectric')) newDeductionFormEl.find('select').selectric('destroy');
      var clonedForm = newDeductionFormEl.clone(true, true)
        .removeClass('hidden')
        .appendTo(deductionListEl);
      startEditingDeduction();
      $(clonedForm).find('select').selectric();
      $(clonedForm).find(".datepicker-js").datepicker();
    } else {
      // prompt to delete all these dedcutions
    }
  });

  /* edit existing deductions */
  $('.deductions-list').on('click', 'a.deduction-edit:not(.disabled)', function(e) {
    e.preventDefault();
    var deductionEl = $(this).parents('.deduction');
    deductionEl.find('.deduction-show').addClass('hidden');
    deductionEl.find('.edit-deduction-form').removeClass('hidden');
    startEditingDeduction();

    $(deductionEl).find(".datepicker-js").datepicker();
    $(deductionEl).find(".datepicker-js").datepicker();
  });

    /* destroy existing deducitons */
  $('.deductions-list').on('click', 'a.deduction-delete:not(.disabled)', function(e) {
    var self = this;
    e.preventDefault();
    $("#destroyDeduction").modal();

    $("#destroyDeduction .modal-cancel-button").click(function(e) {
      $("#destroyDeduction").modal('hide');
    });

    $("#destroyDeduction .modal-continue-button").click(function(e) {
      $("#destroyDeduction").modal('hide');
      $(self).parents('.deduction').remove();

      var url = $(self).parents('.deduction').attr('id').replace('financial_assistance_deduction_', 'deductions/');
      $.ajax({
        type: 'DELETE',
        url: url
      })
    });
  });



  /* cancel benefit edits */
  $('.deductions-list').on('click', 'a.deduction-cancel', function(e) {
    e.preventDefault();
    stopEditingDeduction();

    var benefitEl = $(this).parents('.deduction');
    if (benefitEl.length) {
      benefitEl.find('.deduction-show').removeClass('hidden');
      benefitEl.find('.edit-deduction-form').addClass('hidden');
    } else {
      if (!$(this).parents('.deductions-list > div.deduction').length) {
        $(this).parents('.deduction-kind').find('input[type="checkbox"]').prop('checked', false);
      }
      $(this).parents('.new-deduction-form').remove();
      $(this).parents('.edit-deduction-form').remove();
    }
  });

});

