function getDateFieldDate(id) {
  const dateValue = $(id).val(); 
  return dateValue ? new Date(dateValue) : null;
};

function validateDateWarnings(id, use_bs4 = false) {
  const startDateId = "#start_on_" + id;
  const endDateId = ("#end_on_" + id);
  var startDate = use_bs4 ? getDateFieldDate(startDateId) : $(startDateId).datepicker('getDate');
  var endDate = use_bs4 ? getDateFieldDate(endDateId) : $(endDateId).datepicker('getDate');
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