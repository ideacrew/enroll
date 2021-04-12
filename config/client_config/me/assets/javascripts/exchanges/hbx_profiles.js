function enableOrDisableSubmitButton() {
  if ($('#person_max_aptc').val() != '' && $('#person_csr').val() != '' && $('#jq_datepicker_ignore_person_effective_date').val() != '') {
    $('#create_eligibility').prop('disabled', false);
  }
  else {
    $('#create_eligibility').prop('disabled', true);
  }
}

$(document).on('keyup', "#person_max_aptc", function() {
  enableOrDisableSubmitButton();
});

$(document).on('change', "#person_csr, #jq_datepicker_ignore_person_effective_date", function() {
  enableOrDisableSubmitButton();
});
