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

// ideally, this would be reused as there are a few similar banners
// in benefit_sponsors that reload the page when closed
function closeWarning(event, elementId) {
  event.preventDefault();

  let warning = document.getElementById(elementId);
  warning.classList.add("hidden");
}

window.checkOLKind = checkOLKind;
window.closeWarning = closeWarning;