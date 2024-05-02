// Keyboard navigation for the applicant mailing address form's 'Add Mailing Address' and 'Remove Mailing Address' buttons
function addApplicantMailingAddressKeyboardNavigation() {
  var removeMailingAddressButton = document.getElementById('remove_applicant_mailing_address');
  var addMailingAddressButton = document.getElementById('add_applicant_mailing_address');

  if (removeMailingAddressButton) {
    removeMailingAddressButton.addEventListener('keydown', function(event) {
      handleButtonKeyDown(event, 'remove_applicant_mailing_address');
    });
  }

  if (addMailingAddressButton) {
    addMailingAddressButton.addEventListener('keydown', function(event) {
      handleButtonKeyDown(event, 'add_applicant_mailing_address');
    });
  }
};
