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
      incomeEl = $(this).parents('.income');
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
        incomeEl = $(this).parents('.income');
        incomeEl.find('.income-edit-form').addClass('hidden');
        incomeEl.find('.display-income').removeClass('hidden');
      }
      stopEditingIncome();
    });

    /* new incomes */
    $('a.new-income.btn').click(function(e) {
      e.preventDefault();
      startEditingIncome();
      $(this).siblings('.new-income-form')
        .clone(true)
        .removeClass('hidden')
        .appendTo('.incomes-list');
    });
  }
});
