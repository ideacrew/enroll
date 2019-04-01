function checkOLKind(element) {
  var addressKind = $(element).val();
  var row = $(element).closest(".row").next(".row").next(".row");
  if (addressKind == "primary") {
    row.children('#inputCounty').attr('required', true);
    row.children('#inputCounty').attr('disabled', true);
    row.children('#inputCounty').attr('data-target','zip-check.countySelect');
    row.children('#inputZip').attr('required', true);
    row.children('#inputZip').attr('data-action', 'change->zip-check#zipChange');
  } else {
    row.children('#inputCounty').removeAttr('required');
    row.children('#inputZip').removeAttr('data-action');
    row.children('#inputZip').removeAttr('required');
    row.children('#inputZip').removeAttr('data-options');
    // removes blank option from select options
    //setTimeout(function() {
    //  element.options[0].remove()
    // },300)
  }
}

module.exports = {
  checkOLKind: checkOLKind
};
