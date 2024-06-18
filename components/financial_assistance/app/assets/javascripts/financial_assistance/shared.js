function validateDateWarnings(id, use_bs4 = false) {
  var startDate = use_bs4 ? new Date($("#start_on_" + id).val()) : $("#start_on_" + id).datepicker('getDate');
  var endDate = use_bs4 ? new Date($("#end_on__" + id).val()) : $("#end_on_" + id).datepicker('getDate');
  var today = new Date();
  var requiresStartDateWarning = startDate > today
  var requiresEndDateWarning = endDate
  var warning_div = $("#date_warning_message_" + id);
  var startDateWarning = $("#start_date_warning_" + id)
  var endDateWarning = $("#end_date_warning_" + id)

  warning_div.add(startDateWarning).add(endDateWarning).addClass('hidden');
  if (requiresStartDateWarning) warning_div.add(startDateWarning).removeClass('hidden');
  if (requiresEndDateWarning) warning_div.add(endDateWarning).removeClass('hidden');
};