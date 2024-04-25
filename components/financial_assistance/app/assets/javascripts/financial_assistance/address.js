// Function to hide/show applicant mailing addresses and its related buttons('Add Mailing Address' button, 'Remove Mailing Address' button)
// TODO: Refactor this function to remove the usage of HardCoded Texts.
//       1. Use ids or classes to hide/show the buttons.
//       2. Use ids or classes to hide/show the mailing address fields.
function hideOrShowApplicantMailingAddress() {
  var mailingDivElement = document.querySelector('div.applicant-mailing-address:not(.dn)');

  if (mailingDivElement) {
    mailingDivElement.addEventListener('click', function() {
      var mailingDivs = document.querySelectorAll('.row-form-wrapper.mailing-div');
      var inputFields = document.querySelectorAll("#applicant_addresses_attributes_1_zip, #applicant_addresses_attributes_1_address_1, #applicant_addresses_attributes_1_city, #dependent_addresses_1_address_1, #dependent_addresses_1_zip, #dependent_addresses_1_city");
      var labelFloatlabels = document.querySelectorAll('.mailing-div .label-floatlabel');
      var destroyElement1 = document.querySelector("#applicant_addresses_attributes_1__destroy");

      if (mailingDivElement.textContent.trim() === "Add Mailing Address") {
      // if (mailingDivElement.isSameNode(document.querySelector('#add_applicant_mailing_address'))) {
        mailingDivElement.textContent = 'Remove Mailing Address';
        mailingDivs.forEach(function(div) {
          div.style.display = 'block';
        });
        inputFields.forEach(function(input) {
          input.required = true;
        });
      } else if (mailingDivElement.textContent.trim() === "Remove Mailing Address") {
      // } else if (mailingDivElement.isSameNode(document.querySelector('#remove_applicant_mailing_address'))) {
        mailingDivElement.textContent = 'Add Mailing Address';
        document.querySelectorAll('.mailing-div').forEach(function(div) {
          div.style.display = 'none';
        });

        labelFloatlabels.forEach(function(label) {
          label.style.display = 'none';
        });

        inputFields.forEach(function(input) {
          input.required = false;
        });

        var kindElement = document.querySelector('#applicant_addresses_attributes_1_kind');
        if (kindElement && kindElement.value === "mailing") {
          destroyElement1.value = true;
        }
      }
    });
  }
};
