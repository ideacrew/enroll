function stopEditingDeduction() {
  $('.driver-question, .instruction-row, .deduction-kind').removeClass('disabled');
  $('a.deduction-edit').removeClass('disabled');
  $('.add_new_deduction_kind').removeAttr('disabled');
  $('.col-md-3 > .interaction-click-control-continue').removeClass('disabled');
  $('#nav-buttons a').removeClass('disabled');
  $('.driver-question input, .instruction-row input, .deduction-kind input:not(":input[type=submit], .fake-disabled-input")').removeAttr('disabled');
};

function startEditingDeduction(deduction_kind) {
  $('.driver-question, .instruction-row, .deduction-kind:not(#' + deduction_kind + ')').addClass('disabled');
  $('a.deduction-edit').addClass('disabled');
  $('.add_new_deduction_kind').attr('disabled', true);
  $('.col-md-3 > .interaction-click-control-continue').addClass('disabled');
  $('#nav-buttons a').addClass('disabled');
  $('.driver-question input, .instruction-row input, .deduction-kind:not(#' + deduction_kind + ') input:not(":input[type=submit], .fake-disabled-input")').attr('disabled', true);
};

function currentlyEditing() {
  return $('.interaction-click-control-continue').hasClass('disabled');
};

function deleteDeductions(kind) {
  const requests = $(kind).find('.deductions-list > .deduction').map(function(_, deduction) {
    return $.ajax({
      type: 'DELETE',
      url: $(deduction).attr('id').replace('deduction_', 'deductions/'),
      success: function() {
        $(deduction).remove();
      }
    });
  });
  
  $.when.apply($, requests).done(function() {
    const args = [].slice.apply(arguments);
    const responses = requests.length == 1 ? [args] : args;

    if (responses.every(function(response) { return response[1] == 'success'; })) {
      $(kind).find('input[type="checkbox"]').prop('checked', false);
      $(kind).find('[class^="interaction-click-control-add-more"]').addClass('hidden');
      $(kind).find('.new-deduction-form').addClass('hidden');
      $(kind).find('.add-more-link').addClass('hidden');
    }
  });
}

$(document).on('turbolinks:load', function () {
  if ($('.deduction-kinds').length) {
    $(window).bind('beforeunload', function(e) {
      if (!currentlyEditing() || $('#unsavedDeductionChangesWarning:visible').length)
        return undefined;

      (e || window.event).returnValue = 'You have an unsaved deduction, are you sure you want to proceed?'; //Gecko + IE
      return 'You have an unsaved deduction, are you sure you want to proceed?';
    });

    /* Saving Responses to Deduction  Driver Questions */
    $('#has_deductions_true, #has_deductions_false').on('change', function(e) {
      var attributes = {};
      attributes[$(this).attr('name')] = $(this).val();
      $.ajax({
        type: 'POST',
        url: window.location.pathname.replace('/deductions', ''),
        data: { financial_assistance_applicant: attributes },
        success: function(response){
        }
      })
    });

    $(document).on('click', 'a[href]:not(.disabled)', function(e) {
      if (currentlyEditing()) {
        e.preventDefault();
        var self = this;

        $('#unsavedDeductionChangesWarning').modal('show');
        $('.btn.btn-danger').click(function() {
          window.location.href = $(self).attr('href');
        });

        return false;
      } else
      return true;
    });

    if (!$('#has_deductions_true').is(':checked')) $('.deduction-kinds').addClass('hidden');

    $("#has_deductions_true").change(function(e) {
      if ($(this).is(':checked')) $('.deduction-kinds').removeClass('hidden');
    });

    $("#has_deductions_false").change(function(e) {
      if ($(this).is(':checked')) $('.deduction-kinds').addClass('hidden');
    });

    $('.deduction-kinds').on('click', 'input[type="checkbox"]', function(e) {
      var value = e.target.checked,
          self = this;
      if (value) { // checked deduction kind
        var newDeductionFormEl = $(this).parents('.deduction-kind').children('.new-deduction-form'),
            deductionListEl = $(this).parents('.deduction-kind').find('.deductions-list');
        if (newDeductionFormEl.find('select').data('selectric')) newDeductionFormEl.find('select').selectric('destroy');
        var clonedForm = newDeductionFormEl.clone(true, true)
          .removeClass('hidden')
          .appendTo(deductionListEl);
        startEditingDeduction($(this).parents('.deduction-kind').attr('id'));
        if (!disableSelectric) {
          $(clonedForm).find('select').selectric();
        }
        $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
        e.stopImmediatePropagation();
      } else if (!$(self).parents('.deduction-kind').find('.deductions-list > .deduction').length) { // unchecking deduction kind with no created deductions
        $(self).parents('.deduction-kind').find('.new-deduction-form').addClass('hidden');
        $(self).parents('.deduction-kind').find('.add-more-link').addClass('hidden');
        stopEditingDeduction();
      } else { // unchecking deduction kind with created deductions
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllDeductions").modal();
        var deduction_kind_name = $(this).val().replace(/_/g, ' ');
        deduction_kind_name = deduction_kind_name.charAt(0).toUpperCase() + deduction_kind_name.slice(1);
        $('#deduction_kind_modal').html("for <b>" + deduction_kind_name + "</b>");
        $("#destroyAllDeductions .modal-cancel-button").click(function(e) {
          $("#destroyAllDeductions").modal('hide');
        });

        $("#destroyAllDeductions .modal-continue-button").click(function(e) {
          $("#destroyAllDeductions").modal('hide');
          stopEditingDeduction();

          deleteDeductions($(self).parents('.deduction-kind'));
        });
      }
    });

    $(document).on('click', ".add_new_deduction_kind", function(e) {
      var newDeductionFormEl = $(this).closest('.deduction-kind').children('.new-deduction-form'),
          deductionListEl = $(this).closest('.deduction-kind').find('.deductions-list');
      if (newDeductionFormEl.find('select').data('selectric')) newDeductionFormEl.find('select').selectric('destroy');
      var clonedForm = newDeductionFormEl.clone(true, true)
          .removeClass('hidden')
          .appendTo(deductionListEl);
      startEditingDeduction($(this).parents('.deduction-kind').attr('id'));
      if (!disableSelectric) {
        $(clonedForm).find('select').selectric();
      }
      $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
      e.stopImmediatePropagation();
    });

    /* edit existing deductions */
    $('.deduction-kinds').on('click', 'a.deduction-edit:not(.disabled)', function(e) {
      e.preventDefault();
      var deductionEl = $(this).parents('.deduction');
      deductionEl.find('.deduction-show').addClass('hidden');
      deductionEl.find('.edit-deduction-form').removeClass('hidden');
      startEditingDeduction($(this).parents('.deduction-kind').attr('id'));

      $(deductionEl).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
    });

    /* destroy existing deducitons */
    $('.deduction-kinds').off('click', 'a.deduction-delete:not(.disabled)');
    $('.deduction-kinds').on('click', 'a.deduction-delete:not(.disabled)', function(e) {
      var self = this;
      e.preventDefault();
      $("#destroyDeduction").modal();

      $("#destroyDeduction .modal-cancel-button").click(function(e) {
        $("#destroyDeduction").modal('hide');
      });

      $("#destroyDeduction .modal-continue-button").click(function(e) {
        $("#destroyDeduction").modal('hide');

        var url = $(self).parents('.deduction').attr('id').replace('deduction_', 'deductions/');
        $.ajax({
          type: 'DELETE',
          url: url,
          success: function() {
            if ($(self).parents('.deductions-list').find('.deduction, .new-deduction-form:not(.hidden)').length == 1) {
              $(self).parents('.deduction-kind').find('.add-more-link').addClass('hidden');
              $(self).parents('.deduction-kind').find('input[type="checkbox"]').prop('checked', false);
            }
            $(self).parents('.deduction').remove();
          }
        })
      });
    });

    /* DELETING all Deductions on selcting 'no' on Driver Question */
    $('#has_deductions_false').on('change', function(e) {
      self = this;
      //$('#DestroyExistingJobIncomesWarning').modal('show');
      if ($('.deductions-list .deduction').length) {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllDeductions").modal();

        $("#destroyAllDeductions .modal-cancel-button").click(function(e) {
          $("#destroyAllDeductions").modal('hide');
          $('#has_deductions_true').prop('checked', true).trigger('change');
        });

        $("#destroyAllDeductions .modal-continue-button").click(function(e) {
          $("#destroyAllDeductions").modal('hide');

          $(".deduction-kinds > .deduction-kind").each(function(_, kind) {
            deleteDeductions(kind);
          });
        });
      }
    });

    /* cancel benefit edits */
    $('.deduction-kinds').off('click', 'a.deduction-cancel');
    $('.deduction-kinds').on('click', 'a.deduction-cancel', function(e) {
      e.preventDefault();
      stopEditingDeduction();

      var deductionEl = $(this).parents('.deduction');
      if (deductionEl.length) { // canceling edit of existing deduction
        deductionEl.find('.deduction-show').removeClass('hidden');
        deductionEl.find('.edit-deduction-form').addClass('hidden');
      } else { // canceling edit of new deduction
        if (!$(this).parents('.deductions-list').find('.deduction').length) { // the kind for the canceled new deduction has no existing deductions
          $(this).parents('.deduction-kind').find('input[type="checkbox"]').prop('checked', false);
        }
        $(this).parents('.new-deduction-form').remove();
      }
    });
  }
});
