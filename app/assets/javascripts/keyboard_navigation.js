// keyboard_navigation.js
function handleRadioKeyDown(event, radioId) {
  if (event.key === 'Enter') { 
    document.getElementById(radioId).click(); 
  }
}
  
function handleButtonKeyDown(event, buttonId) {
  if (event.key === 'Enter') { 
    document.getElementById(buttonId).click(); 
  }
}
