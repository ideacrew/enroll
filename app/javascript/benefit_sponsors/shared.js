// the value of the date input is always empty if the user doesn't input a valid date
// to check that if the user was just tabbing through the form, we store the input in a dataset
// to check if the user partially inputted an invalid date as the actual user input is only in the
// shadow DOM
function storeDateInput(event) {
  var input = event.target;
  if (event.key !== "Tab") {
    input.dataset.input += event.key;
  }
}

function checkOLKind(element) {
  var addressKind = $(element).val();
  var row = $(element).closest(".row").next(".row").next(".row");
  if (addressKind == "primary") {
    row.find('#inputCounty').attr('required', true);
    row.find('#inputCounty').prop('disabled', true);
    row.find('#inputCounty').attr('data-target','zip-check.countySelect');
    row.find('#inputZip').attr('required', true);
    row.find('#inputZip').attr('data-action', 'change->zip-check#zipChange');
  } else {
    row.find('#inputCounty').removeAttr('required');
    row.find('#inputCounty').removeAttr('required');
    row.find('#inputZip').removeAttr('data-action');
    row.find('#inputZip').removeAttr('data-action');
    row.find('#inputZip').removeAttr('required');
    row.find('#inputZip').removeAttr('required');
    row.find('#inputZip').removeAttr('data-options');
    row.find('#inputZip').removeAttr('data-options');
    // removes blank option from select options
    //setTimeout(function() {
    //  element.options[0].remove()
    // },300)
  }
}

function closeLanguageWarning(event) {
  event.preventDefault();

  let warning = document.getElementById("languageWarning");
  warning.classList.add("hidden");
}

window.storeDateInput = storeDateInput;
window.checkOLKind = checkOLKind;
window.closeLanguageWarning = closeLanguageWarning;