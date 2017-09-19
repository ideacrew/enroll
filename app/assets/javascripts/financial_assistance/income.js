function stopEditingIncome() {
  $('a.new-income.btn').removeClass('disabled');
  $('a.income-edit').removeClass('disabled');
  $('.col-md-2 > .interaction-click-control-continue').removeClass('disabled');
};

function startEditingIncome() {
  $('a.new-income.btn').addClass('disabled');
  $('a.income-edit').addClass('disabled');
  $('.col-md-2 > .interaction-click-control-continue').addClass('disabled');
};

function currentlyEditing() {
  return $('.interaction-click-control-continue').hasClass('disabled');
};

$(document).ready(function() {
  if ($('.incomes-list').length) {
    $(window).bind('beforeunload', function(e) {
      if (!currentlyEditing() || $('#unsavedIncomeChangesWarning:visible').length)
        return undefined;

      (e || window.event).returnValue = 'You have an unsaved income, are you sure you want to proceed?'; //Gecko + IE
      return 'You have an unsaved income, are you sure you want to proceed?';
    });

    $(document).on('click', 'a[href]:not(.disabled)', function(e) {
      if (currentlyEditing()) {
        e.preventDefault();
        var self = this, warning = $.Deferred;

        $('#unsavedIncomeChangesWarning').modal('show');
        $('.btn.btn-danger').click(function() {
          window.location.href = $(self).attr('href');
        });

        return false;
      } else
        return true;
    });

    /* edit existing incomes */
    $('.incomes-list').on('click', 'a.income-edit:not(.disabled)', function(e) {
      e.preventDefault();
      var incomeEl = $(this).parents('.income');
      incomeEl.find('.display-income').addClass('hidden');
      incomeEl.find('.income-edit-form').removeClass('hidden');
      startEditingIncome();
    });

    /* cancel income edits */
    $('a.income-cancel').click(function(e) {
      e.preventDefault();

      if ($(this).parents('.new-income-form').length) {
        $(this).parents('.new-income-form').remove();
      } else {
        var incomeEl = $(this).parents('.income');
        incomeEl.find('.income-edit-form').addClass('hidden');
        incomeEl.find('.display-income').removeClass('hidden');
      }
      stopEditingIncome();

      /* TODO: Handle unchecking boxes if there are no more incomes of that kind */
    });

    /* new job incomes */
    $('a.new-income.btn').click(function(e) {
      e.preventDefault();

      startEditingIncome();
      $(this).siblings('.new-income-form')
        .clone(true)
        .removeClass('hidden')
        .appendTo($(this).siblings('.incomes-list'));
    });

    /* new other job incomes */
    $('.other-income-checkbox:not(:checked)').click(function(e) {
      if (currentlyEditing()) {
        e.preventDefault();
        return false;
      }

      var incomeListEl = $(this).parents('.income-row').find('.incomes-list');

      startEditingIncome();
      $(this).parents('.incomes').find('.new-income-form')
        .clone(true)
        .removeClass('hidden')
        .appendTo(incomeListEl);
    });

    /* unchecking other income checkboxes */
    $('.other-income-checkbox:checked').click(function(e) {

    });

    /* Condtional Display Job Income Question */
    $("#job_income").addClass('hide');
    $("#has_job_income_true").prop('checked', false)
    $("#has_job_income_false").prop('checked', false)

    $("body").on("change", "#has_job_income_true", function(){
      if ($('#has_job_income_true').is(':checked')) {
        $("#job_income").removeClass('hide');
      } else{
        $("#job_income").addClass('hide');
      }
    });

    $("body").on("change", "#has_job_income_false", function(){
      if ($('#has_job_income_false').is(':checked')) {
        $("#job_income").addClass('hide');
      } else{
        $("#job_income").removeClass('hide');
      }
    });


    /* Condtional Display Self Employed Income Question */
    $("#self_employed_incomes").addClass('hide');
    $("#has_self_employment_income_true").prop('checked', false)
    $("#has_self_employment_income_false").prop('checked', false)

    $("body").on("change", "#has_self_employment_income_true", function(){
      if ($('#has_self_employment_income_true').is(':checked')) {
        $("#self_employed_incomes").removeClass('hide');
      } else{
        $("#self_employed_incomes").addClass('hide');
      }
    });

    $("body").on("change", "#has_self_employment_income_false", function(){
      if ($('#has_self_employment_income_false').is(':checked')) {
        $("#self_employed_incomes").addClass('hide');
      } else{
        $("#self_employed_incomes").removeClass('hide');
      }
    });

    $( "#financial_assistance_income_start_on" ).datepicker();
    $( "#financial_assistance_income_end_on" ).datepicker();
  }
});
