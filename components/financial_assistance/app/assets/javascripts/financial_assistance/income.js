function stopEditingIncome() {
  $('.driver-question, .instruction-row, .income, .other-income-kind').removeClass('disabled');
  $('a.new-income').removeClass('hide');
  $("a[class*='income-edit']").removeClass('disabled');
  $('#new-unemployment-income').removeAttr('disabled');
  $('.add_new_other_income_kind').removeAttr('disabled');
  $('#nav-buttons a').removeClass('disabled');
  $('.col-md-3 > .interaction-click-control-continue').removeClass('disabled');
  $("a.interaction-click-control-add-more").removeClass('hide');
  $('.driver-question input, .instruction-row input, .income input, .other-income-kind input:not(":input[type=submit], .fake-disabled-input")').removeAttr('disabled');
};

function startEditingIncome(income_kind) {
  $('.driver-question, .instruction-row, .income:not(#' + income_kind + '), .other-income-kind:not(#' + income_kind + ')').addClass('disabled');
  $('a.new-income').addClass('hide');
  $("a[class*='income-edit']").addClass('disabled');
  $('#new-unemployment-income').attr('disabled', true);
  $('.add_new_other_income_kind').attr('disabled', true);
  $('#nav-buttons a').addClass('disabled');
  $('.col-md-3 > .interaction-click-control-continue').addClass('disabled');
  $("a.interaction-click-control-add-more").addClass('hide');
  $('.driver-question input, .instruction-row input, .income:not(#' + income_kind + ') input, .other-income-kind:not(#' + income_kind + ') input:not(":input[type=submit]")').attr('disabled', true);
};

function checkDate(income_id) {
  var startDate = $("#start_on_" + income_id).datepicker('getDate');
  var endDate = $("#end_on_" + income_id).datepicker('getDate');

  if ((endDate != "" && endDate != null) && (endDate < startDate)) {
    alert('The end date must be after the start date.')
    $("#end_on_" + income_id)[0].value = ""
    window.event.preventDefault()
  }
}

function currentlyEditing() {
  return $('.interaction-click-control-continue').hasClass('disabled');
};

function deleteIncomes(kind) {
  const requests = $(kind).find('.other-incomes-list > .other-income').map(function(_, deduction) {
    return $.ajax({
      type: 'DELETE',
      url: $(deduction).attr('id').replace('other_income_', ''),
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
      $(kind).find('.new-other-income-form').addClass('hidden');
      $(kind).find('.add-more-link').addClass('hidden');
    }
  });
}

document.addEventListener("turbolinks:load", function () {
  var faWindow = $('.incomes');
  if ($('.incomes-list, .other-incomes-list, .unemployment-incomes .ai-an-incomes').length) {
    $(faWindow).bind('beforeunload', function (e) {
      if (!currentlyEditing() || $('#unsavedIncomeChangesWarning:visible').length)
        return undefined;

      (e || faWindow.event).returnValue = 'You have an unsaved income, are you sure you want to proceed?'; //Gecko + IE
      return 'You have an unsaved income, are you sure you want to proceed?';
    });

    $('a[href]:not(.disabled)').off('click');
    $('a[href]:not(.disabled)').on('click', function(e) {
      if (currentlyEditing()) {
        e.preventDefault();
        var self = this;

        $('#unsavedIncomeChangesWarning').modal('show');
        $(".btn.btn-danger").off('click');
        $('.btn.btn-danger').on('click', function(e) {
          if (self != undefined && faWindow.location != undefined) {
            faWindow.location.href = $(self).attr('href');
          };
        });

        return false;
      } else
        return true;
    });

    /* Saving Responses to  Job Income & Self Employment Driver Questions */
    $('#has_job_income_true, #has_job_income_false, #has_self_employment_income_true, #has_self_employment_income_false').on('change', function (e) {
      var attributes = {};
      attributes[$(this).attr('name')] = $(this).val();
      $.ajax({
        type: 'POST',
        url: window.location.pathname.replace('/incomes', ''),
        data: { financial_assistance_applicant: attributes },
        success: function (response) {
        }
      })
    });

    /* Saving Responses to Other Income Driver Questions */
    $('#has_other_income_true, #has_other_income_false, #has_unemployment_income_true, #has_unemployment_income_false, #has_american_indian_alaskan_native_income_true, #has_american_indian_alaskan_native_income_false').on('change', function (e) {
      var attributes = {};
      attributes[$(this).attr('name')] = $(this).val();
      $.ajax({
        type: 'POST',
        url: window.location.pathname.replace('/incomes', '').replace('/other', ''),
        data: { financial_assistance_applicant: attributes },
        success: function (response) {
        }
      })
    });

    /* DELETING all Job Incomes on selcting 'no' on Driver Question */
    $('#has_job_income_false').on('change', function (e) {
      var self = this;
      //$('#DestroyExistingJobIncomesWarning').modal('show');
      if ($('.incomes-list:not(.self-employed-incomes-list) .income').length) {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllJobIncomes").modal();

        $('#destroyAllJobIncomes .modal-cancel-button"').off('click');
        $('#destroyAllJobIncomes .modal-cancel-button"').on('click', function(e) {
          $("#destroyAllJobIncomes").modal('hide');
          $('#has_job_income_true').prop('checked', true).trigger('change');
        });

        $('#destroyAllJobIncomes .modal-continue-button"').off('click');
        $('#destroyAllJobIncomes .modal-continue-button"').on('click', function(e) {
          $("#destroyAllJobIncomes").modal('hide');
          //$(self).prop('checked', false);

          $('#job_income').find('.incomes-list > .income').each(function (i, job_income) {
            var url = $(job_income).attr('id').replace('income_', 'incomes/');
            $(job_income).remove();
            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });

    /* DELETING all American Indian/Alaskan Native Incomes on selcting 'no' on Driver Question */
    $('#has_american_indian_alaskan_native_income_false').on('change', function (e) {
      var self = this;
      //$('#DestroyExistingJobIncomesWarning').modal('show');
      if ($('.ai-an-incomes-list:not(.other-incomes-list) .ai-an-income').length) {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllAIANIncomes").modal();

        $('#destroyAllAIANIncomes .modal-cancel-button"').off('click');
        $('#destroyAllAIANIncomes .modal-cancel-button"').on('click', function(e) {
          $("#destroyAllAIAN").modal('hide');
          $('#has_american_indian_alaskan_native_income_true').prop('checked', true).trigger('change');
        });

        $('#destroyAllAIANIncomes .modal-continue-button"').off('click');
        $('#destroyAllAIANIncomes .modal-continue-button"').on('click', function(e) {
          $("#destroyAllAIANIncomes").modal('hide');
          //$(self).prop('checked', false);

          $('#ai_an_income').find('.ai-an-incomes-list > .ai-an-income').each(function (i, ai_an_income) {
            var url = $(ai_an_income).attr('id').replace('income_', 'incomes/');
            $(ai_an_income).remove();
            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });

    /* DELETING all Job Incomes on selcting 'no' on Driver Question */
    $('#has_unemployment_income_false').on('change', function (e) {
      var self = this;
      stopEditingIncome();
      //$('#DestroyExistingJobIncomesWarning').modal('show');
      if ($('.unemployment-incomes-list:not(.other-incomes-list) .unemployment-income').length) {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllUnemploymentIncomes").modal('show');

        $("#destroyAllUnemploymentIncomes .modal-cancel-button").off('click');
        $('#destroyAllUnemploymentIncomes .modal-cancel-button').on('click', function(e) {
          $("#destroyAllUnemploymentIncomes").modal('hide');
          $('#has_unemployment_income_true').prop('checked', true).trigger('change');
        });

        $("#destroyAllUnemploymentIncomes .modal-continue-button").off('click');
        $('#destroyAllUnemploymentIncomes .modal-continue-button').on('click', function(e) {
          $("#destroyAllUnemploymentIncomes").modal('hide');
          //$(self).prop('checked', false);

          $('#unemployment_income').find('.unemployment-incomes-list > .unemployment-income').each(function (i, unemployment_income) {
            var url = $(unemployment_income).attr('id').replace('income_', '');
            $(unemployment_income).remove();
            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });

    /* DELETING all Self Employment Incomes on selcting 'no' on Driver Question */
    $('#has_self_employment_income_false').on('change', function (e) {
      self = this;
      //$('#DestroyExistingJobIncomesWarning').modal('show');
      if ($('.self-employed-incomes-list .income').length) {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllSelfEmploymentIncomes").modal();

        $("#destroyAllSelfEmploymentIncomes .modal-cancel-button").off('click');
        $('#destroyAllSelfEmploymentIncomes .modal-cancel-button').on('click', function(e) {
          $("#destroyAllSelfEmploymentIncomes").modal('hide');
          $('#has_self_employment_income_true').prop('checked', true).trigger('change');
        });

        $("#destroyAllSelfEmploymentIncomes .modal-continue-button").off('click');
        $('#destroyAllSelfEmploymentIncomes .modal-continue-button').on('click', function(e) {
          $("#destroyAllSelfEmploymentIncomes").modal('hide');
          //$(self).prop('checked', false);

          $('#self_employed_incomes').find('.self-employed-incomes-list > .income').each(function (i, job_income) {
            var url = $(job_income).attr('id').replace('income_', 'incomes/');
            $(job_income).remove();
            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });

    /* edit existing incomes */
    $('.incomes-list').on('click', 'a.income-edit:not(.disabled)', function (e) {
      e.preventDefault();
      var incomeEl = $(this).parents('.income');
      incomeEl.find('.display-income').addClass('hidden');
      incomeEl.find('.income-edit-form').removeClass('hidden');
      if (!disableSelectric) {
        $(incomeEl).find('select').selectric();
      }
      $(incomeEl).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
      startEditingIncome($(this).parents('.income').attr('id'));
    });


    /* destroy existing job incomes */
    $('.incomes-list').on('click', 'a.income-delete:not(.disabled)', function (e) {
      var self = this;
      e.preventDefault();
      $("#DestroyJobIncomeWarning").modal();

      $("#DestroyJobIncomeWarning .modal-cancel-button").off('click');
      $('#DestroyJobIncomeWarning .modal-cancel-button').on('click', function(e) {
        $("#DestroyJobIncomeWarning").modal('hide');
      });

      $("#DestroyJobIncomeWarning .modal-continue-button").off('click');
      $('#DestroyJobIncomeWarning .modal-continue-button').on('click', function(e) {
        $("#DestroyJobIncomeWarning").modal('hide');
        $(self).parents('.income').remove();

        var url = $(self).parents('.income').attr('id').replace('income_', 'incomes/')
        $.ajax({
          type: 'delete',
          url: url
        })
      });
    });

    /* destroy existing Self Employed Incomes */
    $('.self-employed-incomes-list').on('click', 'a.self-employed-income-delete:not(.disabled)', function (e) {
      var self = this;
      e.preventDefault();
      $("#DestroySelfEmplyedIncomeWarning").modal();

      $("#DestroySelfEmplyedIncomeWarning .modal-cancel-button").off('click');
      $('#DestroySelfEmplyedIncomeWarning .modal-cancel-button').on('click', function(e) {
        $("#DestroySelfEmplyedIncomeWarning").modal('hide');
      });

      $("#DestroySelfEmplyedIncomeWarning .modal-continue-button").off('click');
      $('#DestroySelfEmplyedIncomeWarning .modal-continue-button').on('click', function(e) {
        $("#DestroySelfEmplyedIncomeWarning").modal('hide');
        $(self).parents('.income').remove();

        var url = $(self).parents('.income').attr('id').replace('income_', 'incomes/')
        $.ajax({
          type: 'delete',
          url: url
        })
      });
    });



    /* cancel income edits */
    $('.incomes-list').on('click', 'a.income-cancel', function (e) {
      e.preventDefault();
      var incomeEl = $(this).parents('.income');
      $(this).parents('.new-income-form').addClass("hidden");
      incomeEl.find('.income-edit-form').addClass('hidden');
      incomeEl.find('.display-income').removeClass('hidden');

      var incomeType = this.closest('.incomes-list').parentNode.id
      if (incomeType == 'job_income') {
        if (document.querySelectorAll('.incomes-list:not(.self-employed-incomes-list) .income').length == 0) {
          document.getElementById('has_job_income_false').click();
        }
      } else if (incomeType == 'self_employed_incomes') {
        if (document.querySelectorAll('.self-employed-incomes-list .income').length == 0) {
          document.getElementById('has_self_employment_income_false').click();
        }
      }

      stopEditingIncome();
      $(this).parents('.new-income-form').remove();
      /* TODO: Handle unchecking boxes if there are no more incomes of that kind */
    });

    $(document).on('click', 'a.other-income-cancel', function (e) {
      e.preventDefault();
      stopEditingIncome();

      var otherIncomeEl = $(this).parents('.other-income');
      if (otherIncomeEl.length) { // canceling edit of existing income
        otherIncomeEl.find('.other-income-show').removeClass('hidden');
        otherIncomeEl.find('.edit-other-income-form').addClass('hidden');
      } else { // canceling edit of new income
        if (!$(this).parents('.other-incomes-list').find('.other-income').length) { // the kind for the canceled new income has no existing incomes
          $(this).parents('.other-income-kind').find('input[type="checkbox"]').prop('checked', false);
          $(this).parents('.other-income-kind').find('.add-more-link').addClass('hidden');
          $(this).parents('.other-income-kind').find("a.interaction-click-control-add-more").addClass('hide');
        }
        $(this).parents('.new-other-income-form').remove();
      }
    });

    $(document).on('click', 'a.unemployment-income-cancel', function (e) {
      e.preventDefault();
      stopEditingIncome();

      var unemploymentIncomeEl = $(this).parents('#unemployment-income');
      if (unemploymentIncomeEl.length) { // canceling edit of existing income
        unemploymentIncomeEl.find('.unemployment-income-show').removeClass('hidden');
        unemploymentIncomeEl.find('.edit-unemployment-income-form').addClass('hidden');
      } else { // canceling edit of new income
        if (!$(this).parents('.unemployment-incomes-list').find('#unempoyment-income').length) { // no other existing incomes
          $(this).parents('#unemployment-income').find('#add-more-link-unemployment').addClass('hidden');
          $(this).parents('#unemployment-income').find("a.interaction-click-control-add-more").addClass('hide')

          $('#has_unemployment_income_false').prop('checked', true).trigger('change');
        }

        $(this).parents('.new-unmployment-income-form').remove();
      }
    });

    $(document).on('click', 'a.ai-an-income-cancel', function (e) {
      e.preventDefault();

      if ($(this).parents('.new-ai-an-income-form').length) {
        $(this).parents('.new-ai-an-income-form').addClass('hidden');
      } else {
        var incomeEl = $(this).parents('.income');
      }

      if (document.querySelectorAll('.ai-an-incomes-list:not(.other-incomes-list) .ai-an-income').length == 0) {
        document.getElementById('has_american_indian_alaskan_native_income_false').click();
      }

      stopEditingIncome();

      /* TODO: Handle unchecking boxes if there are no more incomes of that kind */
    });

    // this index is to ensure duplicate hidden forms aren't saved on submit
    var incomeIndex = 0;
    /* new job incomes */
    $("a.new-income").off('click');
    $('a.new-income').on('click', function(e) {
      e.preventDefault();
      startEditingIncome($(this).parents('.income').attr('id'));
      var form = $(this).parents();
      if ($(this).parents('#job_income').children('.new-income-form').length) {
        var newIncomeForm = $(this).parents('#job_income').children('.new-income-form')
      } else {
        var newIncomeForm = $(this).parents('#self_employed_incomes').children('.new-income-form')
      }

      if ($(this).parents('#job_income').find('.incomes-list').length) {
        var incomeListEl = $(this).parents('#job_income').find('.incomes-list');
      } else {
        var incomeListEl = $(this).parents('#self_employed_incomes').find('.incomes-list');
      }
      if (newIncomeForm.find('select').data('selectric')) newIncomeForm.find('select').selectric('destroy');
      var clonedForm = newIncomeForm.clone(true, true)
        .removeClass('hidden')
        .appendTo(incomeListEl);
      if (incomeListEl.children().length > 1 && incomeListEl.children().first().attr('id') === 'hidden-income-form') {
        incomeListEl.children().first().remove();
      }
      if (incomeIndex != 0) {
        var previousForm = clonedForm.prev('.new-income-form');
        previousForm.remove();
      }
      var length = incomeListEl.find(".income").length;
      if (!disableSelectric) {
        $(clonedForm).find('select').selectric();
      }
      //$(newIncomeForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true});
      $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
      clonedForm.find('.interaction-click-control-save').addClass("disabled");
      incomeIndex++;
    });

    // this index is to ensure duplicate hidden forms aren't saved on submit for unemployment incomes
    var unemploymentIndex = 0;
    /* new unemployment incomes */
    $('#new-unemployment-income').off('click');
    $('#new-unemployment-income').on('click', function(e) {
      e.preventDefault();
      startEditingIncome($(this).parents('.unemployment-income').attr('id'));
      var form = $(this).parents();
      var newIncomeForm = $(this).parents('#unemployment_income').children('.new-unemployment-income-form')
      var incomeListEl = $(this).parents('#unemployment_income').find('.unemployment-incomes-list');

      if (newIncomeForm.find('select').data('selectric')) newIncomeForm.find('select').selectric('destroy');
      var clonedForm = newIncomeForm.clone(true, true)
        .removeClass('hidden')
        .appendTo(incomeListEl);
      if (incomeListEl.children().length > 1 && incomeListEl.children().first().attr('id') === 'hidden-income-form') {
        incomeListEl.children().first().remove();
      }
      if (unemploymentIndex != 0) {
        var previousForm = clonedForm.prev('.new-unemployment-income-form');
        previousForm.remove();
      }
      var length = incomeListEl.find(".unemployment-income").length;
      if (!disableSelectric) {
        $(clonedForm).find('select').selectric();
      }
      $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
      clonedForm.find('.interaction-click-control-save').addClass("disabled");
      unemploymentIndex++;
    });

    /* new AI/AN incomes */
    $('a.new-ai-an-income').off('click');
    $('a.new-ai-an-income').on('click', function(e) {
      e.preventDefault();
      startEditingIncome($(this).parents('.ai-an-income').attr('id'));
      var form = $(this).parents();
      var newIncomeForm = $(this).parents('#ai_an_income').children('.new-ai-an-income-form')
      var incomeListEl = $(this).parents('#ai_an_income').find('.ai-an-incomes-list');

      if (newIncomeForm.find('select').data('selectric')) newIncomeForm.find('select').selectric('destroy');
      var clonedForm = newIncomeForm.clone(true, true)
        .removeClass('hidden')
        .appendTo(incomeListEl);
      var length = incomeListEl.find(".ai-an-income").length;
      if (!disableSelectric) {
        $(clonedForm).find('select').selectric();
      }
      $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
      clonedForm.find('.interaction-click-control-save').addClass("disabled");
    });

    $('#has_job_income_true').off('click');
    $('#has_job_income_true').on('click', function(e) {
      startEditingIncome($(this).parents('.income').attr('id'));
      if ($('#job_income').children('.new-income-form').length) {
        var newIncomeForm = $('#job_income').children('.new-income-form')
      }

      if ($('#job_income').find('.incomes-list').length) {
        var incomeListEl = $('#job_income').find('.incomes-list');
      }
      if (newIncomeForm.find('select').data('selectric')) newIncomeForm.find('select').selectric('destroy');
      var clonedForm = newIncomeForm.clone(true, true)
        .removeClass('hidden')
        .appendTo(incomeListEl);
      if (incomeListEl.children().length > 1 && incomeListEl.children().first().attr('id') === 'hidden-income-form') {
        incomeListEl.children().first().remove();
      }
      var length = incomeListEl.find(".income").length;
      if (!disableSelectric) {
        $(clonedForm).find('select').selectric();
      }
      $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
    });
    $('#has_unemployment_income_true').off('click');
    $('#has_unemployment_income_true').on('click', function(e) {
      startEditingIncome($(this).parents('.income').attr('id'));
      if ($('#unemployment_income').children('.new-unemployment-income-form').length) {
        var newIncomeForm = $('#unemployment_income').children('.new-unemployment-income-form')
      }

      if ($('#unemployment_income').find('.unemployment-incomes-list').length) {
        var incomeListEl = $('#unemployment_income').find('.unemployment-incomes-list');
      }
      if (newIncomeForm.find('select').data('selectric')) newIncomeForm.find('select').selectric('destroy');
      if (!$('.unemployment-incomes-list').children('.new-unemployment-income-form').length) {
        var clonedForm = newIncomeForm.clone(true, true)
          .removeClass('hidden')
          .appendTo(incomeListEl);
      }
      var length = incomeListEl.find(".unemployment-income").length;
      if (!disableSelectric) {
        $(clonedForm).find('select').selectric();
      }
      $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
    });

    $("#has_american_indian_alaskan_native_income_true").off('click');
    $('#has_american_indian_alaskan_native_income_true').on('click', function(e) {
      startEditingIncome($(this).parents('.income').attr('id'));
      if ($('#ai_an_income').children('.new-ai-an-income-form').length) {
        var newIncomeForm = $('#ai_an_income').children('.new-ai-an-income-form')
      }

      if ($('#ai_an_income').find('.ai-an-incomes-list').length) {
        var incomeListEl = $('#ai_an_income').find('.ai-an-incomes-list');
      }
      if (newIncomeForm.find('select').data('selectric')) newIncomeForm.find('select').selectric('destroy');
      if (!$('.ai-an-incomes-list').children('.new-ai-an-income-form').length) {
        var clonedForm = newIncomeForm.clone(true, true)
          .removeClass('hidden')
          .appendTo(incomeListEl);
      }
      var length = incomeListEl.find(".ai-an-income").length;
      if (!disableSelectric) {
        $(clonedForm).find('select').selectric();
        $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
      }
    });

    $("#has_self_employment_income_true").off('click');
    $('#has_self_employment_income_true').on('click', function(e) {
      startEditingIncome($(this).parents('.income').attr('id'));
      if ($('#self_employed_incomes').children('.new-income-form').length) {
        var newIncomeForm = $('#self_employed_incomes').children('.new-income-form')
      }
      if ($('#self_employed_incomes').find('.incomes-list').length) {
        var incomeListEl = $('#self_employed_incomes').find('.incomes-list');
      }
      if (newIncomeForm.find('select').data('selectric')) newIncomeForm.find('select').selectric('destroy');
      var clonedForm = newIncomeForm.clone(true, true)
        .removeClass('hidden')
        .appendTo(incomeListEl);
      if (incomeListEl.children().length > 1 && incomeListEl.children().first().attr('id') === 'hidden-self-income-form') {
        incomeListEl.children().first().remove();
      }
      var length = incomeListEl.find(".income").length;
      if (!disableSelectric) {
        $(clonedForm).find('select').selectric();
      }
      $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
    });

    /* Condtional Display Job Income Question */
    if (!$("#has_job_income_true").is(':checked')) $("#job_income").addClass('hidden');
    if (!$("#has_self_employment_income_true").is(':checked')) $("#self_employed_incomes").addClass('hidden');
    if (!$("#has_other_income_true").is(':checked')) $(".other_income_kinds").addClass('hidden');
    if (!$("#has_unemployment_income_true").is(':checked')) $("#unemployment_income").addClass('hidden');
    if (!$("#has_american_indian_alaskan_native_income_true").is(':checked')) $("#ai_an_income").addClass('hidden');

    $("body").on("change", "#has_job_income_true", function () {
      if ($('#has_job_income_true').is(':checked')) {
        $("#job_income").removeClass('hidden');
      } else {
        $("#job_income").addClass('hidden');
      }
    });

    $("body").on("change", "#has_job_income_false", function () {
      if ($('#has_job_income_false').is(':checked')) {
        $("#job_income").addClass('hidden');
        $("#new_income_form").remove();
      } else {
        $("#job_income").removeClass('hidden');
      }
    });

    $("body").on("change", "#has_unemployment_income_true", function () {
      if ($('#has_unemployment_income_true').is(':checked')) {
        $("#unemployment_income").removeClass('hidden');
      } else {
        $("#unemployment_income").addClass('hidden');
      }
    });

    $("body").on("change", "#has_unemployment_income_false", function () {
      if ($('#has_unemployment_income_false').is(':checked')) {
        $("#unemployment_income").addClass('hidden');
      } else {
        $("#unemployment_income").removeClass('hidden');
      }
    });

    $("body").on("change", "#has_american_indian_alaskan_native_income_true", function () {
      if ($('#has_american_indian_alaskan_native_income_true').is(':checked')) {
        $("#ai_an_income").removeClass('hidden');
      } else {
        $("#ai_an_income").addClass('hidden');
      }
    });

    $("body").on("change", "#has_american_indian_alaskan_native_income_false", function () {
      if ($('#has_american_indian_alaskan_native_income_false').is(':checked')) {
        $("#ai_an_income").addClass('hidden');
      } else {
        $("#ai_an_income").removeClass('hidden');
      }
    });

    $("body").on("change", "#has_self_employment_income_true", function () {
      if ($('#has_self_employment_income_true').is(':checked')) {
        $("#self_employed_incomes").removeClass('hidden');
      } else {
        $("#self_employed_incomes").addClass('hidden');
      }
    });

    $("body").on("change", "#has_self_employment_income_false", function () {
      if ($('#has_self_employment_income_false').is(':checked')) {
        $("#self_employed_incomes").addClass('hidden');
      } else {
        $("#self_employed_incomes").removeClass('hidden');
      }
    });

    /* Condtional Display Other Income Question */
    $("body").on("change", "#has_other_income_true", function () {
      if ($('#has_other_income_true').is(':checked')) {
        $(".other_income_kinds").removeClass('hidden');
      } else {
        $(".other_income_kinds").addClass('hidden');
      }
    });

    $("body").on("change", "#has_other_income_false", function () {
      if ($('#has_other_income_false').is(':checked')) {
        $(".other_income_kinds").addClass('hidden');
      } else {
        $(".other_income_kinds").removeClass('hidden');
      }
    });
  }
});

// otherincome checkbox fuctionality
$(document).on('turbolinks:load', function () {
  function disableSave(form) {
    form.find('.interaction-click-control-save').addClass("disabled");
    form.find('.interaction-click-control-save').attr('disabled', 'disabled');
  }

  function enableSave(form) {
    form.find('.interaction-click-control-save').removeClass('disabled');
    form.find('.interaction-click-control-save').removeAttr('disabled');
  }
  $(':input[required=""],:input[required]').on('change', function () {
    var form = $(this).closest('form');
    if (validateForm(form)) {
      enableSave(form)
    } else {
      disableSave(form)
    }
  });

  function validateForm(form) {
    var isValid = true;
    // form.find('#financial_assistance_income_start_on, input[name*=financial_assistance_income[start_on]], input[name*=financial_assistance_income[end_on]]').each(function() {
    //   if ( $(this).val() == '' ||  $(this).val()=='0')
    //     isValid = false;
    // });
    return isValid;
  }

  // $(window).bind('beforeunload', function(e) {
  //   if (!currentlyEditing() || $('#unsavedIncomeChangesWarning:visible').length)
  //     return undefined;

  //   (e || window.event).returnValue = 'You have an unsaved income, are you sure you want to proceed?'; //Gecko + IE
  //   return 'You have an unsaved income, are you sure you want to proceed?';
  // });
  $('input[name="other_income_kind"]').off('click');
  $('input[name="other_income_kind"]').on('click', function(e) {
    var value = e.target.checked;
    self = this;
    if (value) {  // checked deduction kind
      var newOtherIncomeFormEl = $(this).parents('.other-income-kind').children('.new-other-income-form').first();
      otherIncomeListEl = $(this).parents('.other-income-kind').find('.other-incomes-list');
      if (newOtherIncomeFormEl.find('select').data('selectric')) newOtherIncomeFormEl.find('select').selectric('destroy');
      var clonedForm = newOtherIncomeFormEl.clone(true, true)
        .removeClass('hidden')
        .appendTo(otherIncomeListEl);
      startEditingIncome($(this).parents('.other-income-kind').attr('id'));
      if (!disableSelectric) {
        $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
        $(clonedForm).find('select').selectric();
      }
    } else if (!$(self).parents('.other-income-kind').find('.other-incomes-list > .other-income').length) { // unchecked deduction kind with no created deductions
      $(self).parents('.other-income-kind').find('.other-incomes-list').empty();
      $(self).parents('.other-income-kind').find('.add-more-link').addClass('hidden');
      stopEditingIncome();
    } else { // unchecked deduction kind with created deductions
      // prompt to delete all these deductions
      e.preventDefault();
      $("#destroyAllOtherIncomesOfKind").modal();
      $("#destroyAllOtherIncomesOfKind .modal-cancel-button").off('click');
      $('#destroyAllOtherIncomesOfKind .modal-cancel-button').on('click', function(e) {
        $("#destroyAllOtherIncomesOfKind").modal('hide');
      });

      $("#destroyAllOtherIncomesOfKind .modal-continue-button").off('click');
      $('#destroyAllOtherIncomesOfKind .modal-continue-button').on('click', function(e) {
        $("#destroyAllOtherIncomesOfKind").modal('hide');
        stopEditingIncome();
        deleteIncomes($(self).parents('.other-income-kind'))
      });
    }
  });

  /* DELETING all Other Incomes on selecting 'no' on Driver Question */
  $('#has_other_income_false').on('change', function (e) {
    var self = this;

    let other_incomes_exists = false;
    document.querySelectorAll(".other_income_kinds .other-income-kind").forEach(function (kind) {
      if (kind.querySelector('input[type="checkbox"]').checked) {
        other_incomes_exists = true;
      }
    });

    if (other_incomes_exists) {
      e.preventDefault();
      $("#destroyAllOtherIncomes").modal();
      $("#destroyAllOtherIncomes .modal-cancel-button").off('click');
      $('#destroyAllOtherIncomes .modal-cancel-button').on('click', function(e) {
        $("#destroyAllOtherIncomes").modal('hide');
      });

      $("#destroyAllOtherIncomes .modal-continue-button").off('click');
      $('#destroyAllOtherIncomes .modal-continue-button').on('click', function(e) {
        $("#destroyAllOtherIncomes").modal('hide');

        $(".other_income_kinds .other-income-kind").each(function (_, kind) {
          deleteIncomes($(kind));
        });
      });
    }
  });

  // this index is to ensure duplicate hidden forms aren't saved on submit
  var otherIndex = 0;
  $(document).on('click', ".add_new_other_income_kind", function (e) {
    var newOtherIncomeFormEl = $(this).parents('.other-income-kind').children('.new-other-income-form'),
      otherIncomeListEl = $(this).parents('.other-income-kind').find('.other-incomes-list');
    if (newOtherIncomeFormEl.find('select').data('selectric')) newOtherIncomeFormEl.find('select').selectric('destroy');
    var clonedForm = newOtherIncomeFormEl.clone(true, true)
      .removeClass('hidden')
      .appendTo(otherIncomeListEl);
    if (otherIncomeListEl.children().length > 1 && otherIncomeListEl.children().first().attr('id') === 'hidden-other-income-form') {
      incomeListEl.children().first().remove();
    }
    if (otherIndex != 0) {
      var previousForm = clonedForm.prev('.new-other-income-form');
      previousForm.remove();
    }
    startEditingIncome($(this).parents('.other-income-kind').attr('id'));
    if (!disableSelectric) {
      $(clonedForm).find('select').selectric();
    }
    $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
    e.stopImmediatePropagation();
    otherIndex++;
  });

  /* edit existing other income */
  $('.other-incomes-list').off('click', 'a.other-income-edit:not(.disabled)');
  $('.other-incomes-list').on('click', 'a.other-income-edit:not(.disabled)', function (e) {
    e.preventDefault();
    var otherIncomeEl = $(this).parents('.other-income');
    otherIncomeEl.find('.other-income-show').addClass('hidden');
    otherIncomeEl.find('.edit-other-income-form').removeClass('hidden');
    startEditingIncome($(this).parents('.other-income-kind').attr('id'));

    $(otherIncomeEl).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
  });

  /* destroy existing other income */
  $('.other-incomes-list').on('click', 'a.other-income-delete:not(.disabled)', function (e) {
    var self = this;
    e.preventDefault();
    $("#destroyOtherIncome").modal();

    $("#destroyOtherIncome .modal-cancel-button").off('click');
    $('#destroyOtherIncome .modal-cancel-button').on('click', function(e) {
      $("#destroyOtherIncome").modal('hide');
    });

    $("#destroyOtherIncome .modal-continue-button").off('click');
    $('#destroyOtherIncome .modal-continue-button').on('click', function(e) {
      $("#destroyOtherIncome").modal('hide');

      var url = $(self).parents('.other-income').attr('id').replace('financial_assistance_income_', '');
      $.ajax({
        type: 'DELETE',
        url: url,
        dataType: 'script',
        success: function() {
          if ($(self).parents('.other-incomes-list').find('.other-income, .new-other-income-form:not(.hidden)').length == 1) {
            $(self).parents('.other-income-kind').find('input[type="checkbox"]').prop('checked', false);
            $(self).parents('.other-income-kind').find('.add-more-link').addClass('hidden');
            $(self).parents('.other-income-kind').find("a.interaction-click-control-add-more").addClass('hide');
          }
          $(self).parents('.other-income').remove();
        }
      })
    });
  });

  /* cancel other income edits */
  $('.other-incomes-list').off('click', 'a.other-income-cancel');
  $('.other-incomes-list').on('click', 'a.other-income-cancel', function (e) {
    e.preventDefault();
    stopEditingIncome();

    var otherIncomeEl = $(this).parents('.other-income');
    if (otherIncomeEl.length) { // canceling edit of existing income
      otherIncomeEl.find('.other-income-show').removeClass('hidden');
      otherIncomeEl.find('.edit-other-income-form').addClass('hidden');
    } else { // canceling edit of new income
      if (!$(this).parents('.other-incomes-list').find('.other-income').length) { // the kind for the canceled new income has no existing incomes
        $(this).parents('.other-income-kind').find('input[type="checkbox"]').prop('checked', false);
        $(this).parents('.other-income-kind').find('.add-more-link').addClass('hidden');
        $(this).parents('.other-income-kind').find("a.interaction-click-control-add-more").addClass('hide');
      }
      $(this).parents('.new-other-income-form').remove();
    }
  });

  /* edit existing unemployment income */
  $('a.unemployment-income-edit:not(.disabled)').off('click');
  $('a.unemployment-income-edit:not(.disabled)').on('click', function(e) {
    e.preventDefault();

    var unemploymentIncomeEl = $(this).parents('.unemployment-income');
    unemploymentIncomeEl.find('.unemployment-income-show').addClass('hidden');
    unemploymentIncomeEl.find('.edit-unemployment-income-form').removeClass('hidden');

    startEditingIncome($(this).parents('.unemployment-income-kind').attr('id'));

    $(unemploymentIncomeEl).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
  });

  /* destroy existing unemployment income */
  $('a.unemployment-income-delete:not(.disabled)').off('click');
  $('a.unemployment-income-delete:not(.disabled)').on('click', function(e) {
    var self = this;
    e.preventDefault();
    $("#destroyUnemploymentIncome").modal();

    $("#destroyUnemploymentIncome .modal-cancel-button").off('click');
    $('#destroyUnemploymentIncome .modal-cancel-button').on('click', function(e) {
      $("#destroyUnemploymentIncome").modal('hide');
    });

    $("#destroyUnemploymentIncome .modal-continue-button").off('click');
    $('#destroyUnemploymentIncome .modal-continue-button').on('click', function(e) {
      $("#destroyUnemploymentIncome").modal('hide');

      var url = $(self).parents('.unemployment-income').attr('id').replace('financial_assistance_income_', '');
      $.ajax({
        type: 'DELETE',
        url: url,
        dataType: 'script',
        success: function() {
          if ($(self).parents('.unemployment-incomes-list').find('.unemployment-income, .new-unemployment-income-form:not(.hidden)').length == 1) {
            $("#add-more-link-unemployment").addClass('hidden');
            $("a.interaction-click-control-add-more").addClass('hide');
          }
          $(self).parents('.unemployment-income').remove();
        }
      });
    });
  });

  /* cancel unemployment income edits */
  $('.unemployment-incomes-list').on('click', 'a.unemployment-income-cancel', function (e) {
    e.preventDefault();
    stopEditingIncome();

    var unemploymentIncomeEl = $(this).parents('.unemployment-income');
    if (unemploymentIncomeEl.length) {
      $(this).closest('.unemployment-income-kind').find('a#add_new_unemployment_income_kind').removeClass("hidden");
      unemploymentIncomeEl.find('.unemployment-income-show').removeClass('hidden');
      unemploymentIncomeEl.find('.edit-unemployment-income-form').addClass('hidden');
    } else {
      if (!$(this).parents('.unemployment-incomes-list > div.unemployment-income').length) {
        $(this).parents('.unemployment-income-kind').find('input[type="checkbox"]').prop('checked', false);
        $(this).closest('.unemployment-income-kind').find('a#add_new_unemployment_income_kind').addClass("hidden");
      }
      $(this).parents('.new-unemployment-income-form').remove();
      $(this).parents('.edit-unemployment-income-form').remove();
    }
  });

  /* edit existing AI/AN income */
  $('.ai-an-incomes-list').on('click', 'a.ai-an-income-edit:not(.disabled)', function (e) {
    e.preventDefault();
    var aianIncomeEl = $(this).parents('.ai-an-income');
    aianIncomeEl.find('.ai-an-income-show').addClass('hidden');
    aianIncomeEl.find('.edit-ai-an-income-form').removeClass('hidden');
    startEditingIncome($(this).parents('.ai-an-income-kind').attr('id'));

    $(aianIncomeEl).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110" });
  });

  /* destroy existing AI/AN income */
  $('.ai-an-incomes-list').on('click', 'a.ai-an-income-delete:not(.disabled)', function (e) {
    var self = this;
    e.preventDefault();
    $("#destroyAIANIncome").modal();

    $("#destroyAIANIncome .modal-cancel-button").off('click');
    $('#destroyAIANIncome .modal-cancel-button').on('click', function(e) {
      $("#destroyAIANIncome").modal('hide');
    });

    $("#destroyAIANIncome .modal-continue-button").off('click');
    $('#destroyAIANIncome .modal-continue-button').on('click', function(e) {
      $("#destroyAIANIncome").modal('hide');
      $(self).parents('.ai-an-income').remove();
      $("a.interaction-click-control-add-more").addClass('hide');

      var url = $(self).parents('.ai-an-income').attr('id').replace('financial_assistance_income_', '');
      $.ajax({
        type: 'DELETE',
        url: url,
        dataType: 'script',
      })
    });
  });

  /* cancel AI/AN income edits */
  $('.ai-an-incomes-list').on('click', 'a.ai-an-income-cancel', function (e) {
    e.preventDefault();
    stopEditingIncome();

    var aianIncomeEl = $(this).parents('.ai-an-income');
    if (aianIncomeEl.length) {
      $(this).closest('.ai-an-income-kind').find('a#add_new_ai_an_income_kind').removeClass("hidden");
      aianIncomeEl.find('.ai-an-income-show').removeClass('hidden');
      aianIncomeEl.find('.edit-ai-an-income-form').addClass('hidden');
    } else {
      if (!$(this).parents('.ai-an-incomes-list > div.ai-an-income').length) {
        $(this).parents('.ai-an-income-kind').find('input[type="checkbox"]').prop('checked', false);
        $(this).closest('.ai-an-income-kind').find('a#add_new_ai_an_income_kind').addClass("hidden");
      }
      $(this).parents('.new-ai-an-income-form').remove();
      $(this).parents('.edit-ai-an-income-form').remove();
    }
  });
  // disable save button logic
  function disableSave(form) {
    form.find('.interaction-click-control-save').addClass("disabled");
    form.find('.interaction-click-control-save').attr('disabled', 'disabled');
  }

  function enableSave(form) {
    form.find('.interaction-click-control-save').removeClass('disabled');
    form.find('.interaction-click-control-save').removeAttr('disabled');
  }

  $(':input[required]').on('keyup change', function () {
    var form = $(this).closest('form');
    if (validateForm(form)) {
      enableSave(form)
    } else {
      disableSave(form)
    }
  });

  function validateForm(form) {
    var isValid = true;
    form.find(':input[required]').each(function () {
      if ($(this).val() == '' || $(this).val() == '0.00' || $(this).val() == 'Choose') {
        isValid = false;
      }
    });
    return isValid;
  }


  $('body').on('keyup keydown keypress', '#income_employer_phone_full_phone_number', function (e) {
    var key = e.which || e.keyCode || e.charCode;
    $(this).mask('(000) 000-0000');
    return (key == 8 ||
      key == 9 ||
      key == 46 ||
      (key >= 37 && key <= 40) ||
      (key >= 48 && key <= 57) ||
      (key >= 96 && key <= 105));
  });

  $('body').on('keyup keydown keypress', '#income_employer_address_zip', function (e) {
    var key = e.which || e.keyCode || e.charCode;
    $(this).attr('maxlength', '5');
    return (key == 8 ||
      key == 9 ||
      key == 46 ||
      (key >= 37 && key <= 40) ||
      (key >= 48 && key <= 57) ||
      (key >= 96 && key <= 105));
  });
});
