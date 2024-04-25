document.addEventListener('DOMContentLoaded', function() {
  var removeMailingAddressButton = document.getElementById('remove_applicant_mailing_address');

  if (removeMailingAddressButton) {
    removeMailingAddressButton.addEventListener('keydown', function(event) {
      handleButtonKeyDown(event, 'remove_applicant_mailing_address');
    });
  }
});

document.addEventListener('DOMContentLoaded', function() {
  var removeMailingAddressButton = document.getElementById('add_applicant_mailing_address');

  if (removeMailingAddressButton) {
    removeMailingAddressButton.addEventListener('keydown', function(event) {
      handleButtonKeyDown(event, 'add_applicant_mailing_address');
    });
  }
});
