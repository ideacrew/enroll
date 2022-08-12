// Framework for setting temporary "warning" messages
// validation_function must return a boolean
// After the user closes out fo the temporary form, the temporary_warning_hidden_input will be set to true
// and will not appear anymore

function temporaryWarningAccepted(form_object_id) {
  var temporary_warning_hidden_input = document.getElementById("temporary_warning_message_" + form_object_id + "_seen")
  temporary_warning_hidden_input.value = 'true';
}

// Add further validations here
function setValidationFunction(form_type, form_object_id) {
  if (form_type == 'income') {
    return validateIncomeForTemporaryMessage(form_object_id);
  }
}

// Specific Condition Validation for income
// Will return true (throw the warning message) if:
// 1) Start Date is greater than current date
// 2) End Date is anything other than blank
function validateIncomeForTemporaryMessage(income_id) {
  var startDate = document.getElementById("start_on_" + income_id).value;
  var endDate = document.getElementById("end_on_" + income_id).value;
  var startDateToDate = new Date(startDate);
  var endDateToDate = new Date(endDate);
  var today = new Date()
  if (startDateToDate > today) {
    return true;
  } else if (endDate) {
    return true;
  } else {
    return false;
  }
}

function showTemporaryMessageDiv(form_object_id, form_type) {
  var temporary_warning_hidden_input_id = "temporary_warning_message_" + form_object_id + "_seen"
  var temporary_warning_hidden_input = document.getElementById(temporary_warning_hidden_input_id);
  var warning_div = document.getElementById("temporary_warning_message_" + form_object_id);
  var validation_function = setValidationFunction(form_type, form_object_id);
  if (temporary_warning_hidden_input.value != 'true' && validation_function == true) {
    warning_div.classList.remove('hidden');
    window.event.preventDefault();
  };
}

function validateDateWarnings(id) {
  var startDate = $("#start_on_" + id).datepicker('getDate');
  var endDate = $("#end_on_" + id).datepicker('getDate');
  var today = new Date();
  var requiresStartDateWarning = startDate > today
  var requiresEndDateWarning = endDate
  var warning_div = $("#date_warning_message_" + id);
  var startDateWarning = $("#start_date_warning_" + id)
  var endDateWarning = $("#end_date_warning_" + id)

  if (warning_div.is(":visible") && !requiresStartDateWarning && !requiresEndDateWarning) {
    warning_div.addClass('hidden');
    return;
  }

  if (requiresStartDateWarning || requiresEndDateWarning) {
    warning_div.removeClass('hidden');
    if (startDate > today) {
      startDateWarning.removeClass('hidden');
    } else {
      startDateWarning.addClass('hidden');
    }
    if (endDate) {
      endDateWarning.removeClass('hidden');
    } else {
      endDateWarning.addClass('hidden');
    }
  }
};