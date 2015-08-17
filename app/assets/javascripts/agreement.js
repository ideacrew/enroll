var checkBoxes = $('[id$="check_thank_you"]'),
    submitButton = $('#btn-continue');

  checkBoxes.change(function () {
      submitButton.prop("disabled", checkBoxes.is(":not(:checked)"));
      if(checkBoxes.is(":not(:checked)")) {
          submitButton.prop("disabled",true);
      } else {
          submitButton.removeAttr('disabled');
      }
});
