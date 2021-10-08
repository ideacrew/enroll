window.onload = function() {
  // Nothing for right now
}

function lettersOnly(input) {
  var regex = /[^a-z]/gi;
  input.value = input.value.replace(regex,"");
}


function toCurrency(element) {
  element.value = element.value.replace(/[^0-9.]/g, '').replace(/(\..*)\./g, '$1')
}

// Prevents dates entered outside of minDate/maxDate from being submitted
function validateDate(element, minDate, maxDate) {
  var selectedDate = new Date(element.target.value)

  if (selectedDate < minDate) {
    swal("Invalid Date!","Date entered is less then the minimum allowable date","error");
    element.target.value = '';
  }

  if (selectedDate > maxDate) {
    swal("Invalid Date!","Date entered exceeds maximum allowed date","error");
    element.target.value = '';
  }
}

// Prevents non numeric characters
function isNumberKey(evt){
  {
    var charCode = (evt.which) ? evt.which : event.keyCode
    if (charCode > 31 && (charCode < 48 || charCode > 57))
      return false;

    return true;
  }
}

// Prevents non alphanumeric characters from being typed
function isAlphaNumeric(event) {
  var character = String.fromCharCode(event.keyCode);
  const alpha = Array.from(Array(26)).map((e, i) => i + 65);
  const alphabet = alpha.map((x) => String.fromCharCode(x));
  var number_regex = /^\d+$/;
  var char_uppercase = character.toUpperCase();
  if (number_regex.test(character) == true || alphabet.includes(char_uppercase) == true) {
    return true;
  } else {
    return false;
  }
}

// Formats dates for Benefit Applications
function getFormattedDate(date){
  var new_date = new Date(date)
  var dd = new_date.getUTCDate();
  var mm = new_date.getUTCMonth()+1;
  var yyyy = new_date.getUTCFullYear();
  if(dd<10) {
    dd='0'+dd
  }
  if(mm<10) {
    mm='0'+mm
  }
  formatted_date = mm+'/'+dd+'/'+yyyy;
  return formatted_date;
}

function validateEmailFormat(element) {
  var emailAddress = element.value;
  if (!isEmail(emailAddress)) {
    swal({
      icon: 'error',
      title: 'Invalid Email Entered',
      text: 'The email entered is not in a valid format, please check your entry and submit the information again.'
    })
    element.value = '';
  }
}

function isEmail(email) {
    return /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))$/i.test(email);
}
