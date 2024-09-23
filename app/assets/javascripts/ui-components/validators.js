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
  //https://html.spec.whatwg.org/multipage/input.html#valid-e-mail-address
  return /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/i.test(email);
}
