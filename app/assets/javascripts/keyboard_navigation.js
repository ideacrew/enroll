// keyboard_navigation.js
function handleRadioKeyDown(event, radioId) {
  if (event.key === 'Enter') {
    document.getElementById(radioId).click();
  }
}

function handleCitizenKeyDown(event, radioIdBase) {
  if (event.key === 'Enter') {
    const personElement = document.getElementById(`person_${radioIdBase}`);
    const dependentElement = document.getElementById(`dependent_${radioIdBase}`);

    if (personElement) {
      personElement.click();
    } else if (dependentElement) {
      dependentElement.click();
    }
  }
}

function handleContactInfoKeyDown(event, radioId, modifyDiv) {
  if (event.key === 'Enter') {
    document.getElementById(radioId).click();
    hidden_div = document.getElementById(modifyDiv);
    if (hidden_div.style.display === "block") {
      hidden_div.style.display = "none";
    } else {
      hidden_div.style.opacity = "1";
      hidden_div.style.display = "block";
    }
  }
}

function handleButtonKeyDown(event, buttonId) {
  if (event.key === 'Enter') {
    document.getElementById(buttonId).click();
  }
}

function handleSEPRadioButton(buttonId) {
  document.getElementById(buttonId).click();
}

function handleCancelButtonKeyDown(event, buttonId, hideForm) {
  if (event.key === 'Enter') {
    document.getElementById(buttonId).click();
    document.getElementById(hideForm).classList.add('hidden');
  }
}

function handleGlossaryFocus(glossaryId) {
  $("#" + glossaryId).popover('show');
}

function handleGlossaryBlur(glossaryId) {
  $("#" + glossaryId).popover('hide');
}

function handleGlossaryKeydown(event, glossaryId) {
  if (event.key === 'Tab' || event.key === 'Enter') {
    $("#" + glossaryId).popover('show');
  } else {
    $("#" + glossaryId).popover('hide');
  }
}

window.addEventListener('keydown', function(event) {
  if (event.keyIdentifier == 'U+000A' || event.keyIdentifier == 'Enter' || event.key === 'Enter') {
    if (event.target.nodeName == 'INPUT' && event.target.type !== 'text' && event.target.type !== 'textarea') {
      var form = event.target.closest('form');
      var reqCheckboxLists = form.querySelectorAll('.req-checkbox-group');
      var requiredChecklists = [...reqCheckboxLists];
      var checkListFail = false;
      requiredChecklists.forEach(function(reqCheckbox) {
        if (reqCheckbox.querySelectorAll('input[type="checkbox"]:checked').length == 0) {
          checkListFail = true
          reqCheckbox.classList.add('invalid');
        } else {
          reqCheckbox.classList.remove('invalid');
        }
      });
      if (form.checkValidity() === false || checkListFail) {
        event.preventDefault();
        event.stopPropagation();
        form.classList.add('was-validated');
      } else {
        form.classList.remove('was-validated');
      }
    }
  }
}, true);
