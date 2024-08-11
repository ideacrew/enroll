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
