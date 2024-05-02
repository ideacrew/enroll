// Function to hide/show applicant mailing addresses and its related buttons('Add Mailing Address' button, 'Remove Mailing Address' button)
function hideOrShowApplicantMailingAddress() {
  var displayMailingDivElement = document.querySelector('div.applicant-mailing-address:not(.dn)');
  var mailingDivElements = document.querySelectorAll('div.applicant-mailing-address');

  if (displayMailingDivElement) {
    mailingDivElements.forEach(function(mailingDivElement) {
      mailingDivElement.addEventListener('click', function() {
        var mailingDivs = document.querySelectorAll('.row-form-wrapper.mailing-div');
        var inputFields = document.querySelectorAll("#applicant_addresses_attributes_1_zip, #applicant_addresses_attributes_1_address_1, #applicant_addresses_attributes_1_city, #dependent_addresses_1_address_1, #dependent_addresses_1_zip, #dependent_addresses_1_city");
        var labelFloatlabels = document.querySelectorAll('.mailing-div .label-floatlabel');
        var destroyElement1 = document.querySelector("#applicant_addresses_attributes_1__destroy");
        var addMailingAddressElement = document.querySelector('#add_applicant_mailing_address');
        var removeMailingAddressElement = document.querySelector('#remove_applicant_mailing_address');

        if (addMailingAddressElement.isSameNode(document.querySelector('div.applicant-mailing-address:not(.dn)'))) {
          addMailingAddressElement.classList.add('dn');
          removeMailingAddressElement.classList.remove('dn');
          mailingDivs.forEach(function(div) {
            div.style.display = 'block';
          });
          inputFields.forEach(function(input) {
            input.required = true;
          });
        } else if (removeMailingAddressElement.isSameNode(document.querySelector('div.applicant-mailing-address:not(.dn)'))) {
          addMailingAddressElement.classList.remove('dn');
          removeMailingAddressElement.classList.add('dn');

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
    });
  }
};
