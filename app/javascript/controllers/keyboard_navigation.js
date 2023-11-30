// keyboard_navigation.js

function handleRadioKeyDown(event, radioId, otherRadioId) {
    if (event.key === 'Enter') {
      event.preventDefault();
      const radio = document.getElementById(radioId);
      const otherRadio = document.getElementById(otherRadioId);
      radio.checked = true;
      otherRadio.checked = false;
      radio.setAttribute("aria-pressed", "true");
      otherRadio.setAttribute("aria-pressed", "false");
    }
  }
  
  function handleTribeRadioKeyDown(event, radioId, otherRadioId) {
    if (event.key === 'Enter') {
      event.preventDefault();
      const radio = document.getElementById(radioId);
      const otherRadio = document.getElementById(otherRadioId);
      radio.checked = true;
      otherRadio.checked = false;
      document.getElementById('tribal_container_test').classList.remove('hide');
    }
  }