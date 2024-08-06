import { Controller } from "stimulus";
import Swal from 'sweetalert2';

export default class extends Controller {

  static targets = [ "passwordField", "usernameField", "passwordConfirmationField", "optionalEmail" ]

connect() {
  // Equivalent to document ready
  this.getForms();
  this.checkRegistrationRules();
}

getForms() {
  // Fetch all the forms we want to apply custom Bootstrap validation styles to
  let forms = document.getElementsByClassName('needs-validation');
  // Loop over them and prevent submission
  Array.prototype.filter.call(forms, function(form) {
    form.addEventListener('submit', function(event) {
      if (form.checkValidity() === false) {
        event.preventDefault();
        event.stopPropagation();
      }
      form.classList.add('was-validated');
    }, false);
  });
}

emailTooltip() {
  this.hideTooltips();
  $('#user_oim_id').tooltip('show');
}

passwordTooltip() {
  let passwordLength = document.getElementById("user_password").minLength;
  const passwordHelper =
    `<p>Your password must:</p>
     <ul class="list-group pwHelper">
      <li id="length" class="invalid"><i class="fa fa-times mr-3 length"></i>Be at least ${passwordLength} characters</li>
      <li id="longer" class="invalid"><i class="fa fa-times mr-3 longer"></i>Not be longer than 20 characters</li>
      <li id="lower" class="invalid"><i class="fa fa-times mr-3 lower"></i>Include at least one lowercase letter</li>
      <li id="upper" class="invalid"><i class="fa fa-times mr-3 upper"></i>Include at least one uppercase letter</li>
      <li id="number" class="invalid"><i class="fa fa-times mr-3 number"></i>Include at least one number</li>
      <li id="spec_char" class="invalid"><i class="fa fa-times mr-3 spec_char"></i>Include at least one special character ($!@%*&)</li>
      <li id="mtt" class="invalid"><i class="fa fa-times mr-3 mtt"></i>Cannot repeat any character more than 4 times</li>
      <li id="wh_space" class="invalid"><i class="fa fa-times mr-3 wh_space"></i>Not include blank spaces</li>
      <li id="nm_uid" class="invalid"><i class="fa fa-times mr-3 nm_uid"></i>Cannot contain username</li>
     </ul>
  `
  this.hideTooltips();
  $('#user_password').attr('data-title', passwordHelper);
  $('#user_password').tooltip('show');
}

hideTooltips() {
  $('#user_oim_id').tooltip('hide');
  $('#user_password').tooltip('hide');
}

validateInput() {
  // Password text must be present
  if (this.passwordFieldTarget.value.length > 0 && document.querySelector('.pwHelper')) {
    const value = this.passwordFieldTarget.value;
    const minLength = document.getElementById("user_password").minLength;
    this.checkMinLength(value, minLength);
    this.checkMaxLength(value);
    this.validateNumber(value);
    this.validateSpecialCharacters(value);
    this.validateUpCase(value);
    this.validateLowerCase(value);
    this.validateRepeatedChar(value);
    this.validateWhiteSpace(value);
    this.validateUserIdMatch(value);
    this.passwordComplexity(value, minLength);
  } else if (this.passwordFieldTarget.value.length === 0) {
    // this.resetTooltips(['number', 'spec_char', 'mtt', 'wh_space', 'nm_uid']);
  }
}

resetMinLengthIcon() {
  if (document.querySelector('.pwHelper')) {
    document.querySelector('.length').classList.remove('fa-check');
    document.getElementById('length').style.color = '';
    document.querySelector('.length').classList.add('fa-times');
  }
}

resetMaxLengthIcon() {
  if (document.querySelector('.pwHelper')) {
    document.querySelector('.longer').classList.remove('fa-check');
    document.getElementById('longer').style.color = '';
    document.querySelector('.longer').classList.add('fa-times');
  }
}

checkMinLength(value, minLength) {
  if (value.length >= minLength) {
    document.querySelector('.length').classList.add('fa-check');
  } else if (value.length < minLength && this.usernameFieldTarget.value.length > 0) {
    this.resetMinLengthIcon();
  }
}

checkMaxLength(value, minLength) {
  if ((value.length > 0 && value.length <= 20)) {
    document.querySelector('.longer').classList.add('fa-check');
  } else if (value.length < minLength && this.usernameFieldTarget.value.length > 0) {
    this.resetMaxLengthIcon();
  }
}

validateUpCase(value) {
  if (value.match(/[A-Z]/)) {
    document.querySelector('.upper').classList.add('fa-check');
  } else {
    document.querySelector('.upper').classList.remove('fa-check');
    document.querySelector('.upper').classList.add('fa-times');
    document.getElementById('upper').style.color = '';
  }
}

validateNumber(value) {
  if (value.match(/[0-9]/)) {
    document.querySelector('.number').classList.add('fa-check');
  } else {
    document.querySelector('.number').classList.remove('fa-check');
    document.querySelector('.number').classList.add('fa-times');
    document.getElementById('number').style.color = '';
  }
}

validateSpecialCharacters(value) {
  if (value.match(/.[!,@,#,$,%,^,&,*,?,_,~,-,(,)]/)) {
    document.querySelector('.spec_char').classList.add('fa-check');
  } else {
    document.querySelector('.spec_char').classList.remove('fa-check');
    document.querySelector('.spec_char').classList.add('fa-times');
    document.getElementById('spec_char').style.color = '';
  }
}

validateLowerCase(value) {
  if (value.match(/[a-z]/)) {
    document.querySelector('.lower').classList.add('fa-check');
  } else {
    document.querySelector('.lower').classList.remove('fa-check');
    document.querySelector('.lower').classList.add('fa-times');
    document.getElementById('lower').style.color = '';
  }
}

validateRepeatedChar(value) {
  const max_repeats = 4;
  let pass_str = value;
  const chars = pass_str.split('');
  const cmap = {};

  if (value.length < 1) {
    document.querySelector('.mtt').classList.remove('fa-check');
    document.querySelector('.mtt').classList.add('fa-times');
    document.getElementById('mtt').style.color = '';
  }
  for (var i = 0; i < chars.length; i++) {
        if (!cmap.hasOwnProperty(chars[i])) cmap[chars[i]] = 0;
        cmap[chars[i]]++;
      }
  for (let p in cmap) {
    if (cmap[p] > max_repeats){
      document.querySelector('.mtt').classList.remove('fa-check');
      document.querySelector('.mtt').classList.add('fa-times');
      document.getElementById('mtt').style.color = '';
    } else {
      document.querySelector('.mtt').classList.add('fa-check');
    }
  }
}

validateWhiteSpace(value) {
  if (value.match(/\s/)) {
    document.querySelector('.wh_space').classList.add('fa-times');
    document.getElementById('wh_space').style.color = '';
  } else {
    document.querySelector('.wh_space').classList.add('fa-check');
  }
}

validateUserIdMatch(value) {
  if (this.usernameFieldTarget.value.length > 0 && this.passwordFieldTarget.value.indexOf(this.usernameFieldTarget.value) >= 0) {
    document.querySelector('.nm_uid').classList.add('fa-times');
    document.getElementById('nm_uid').style.color = '';
  } else {
    document.querySelector('.nm_uid').classList.add('fa-check');
  }
}

passwordComplexity(value, minPasswordLength) {
  const num = {};
  num.Excess = 0;
  num.Upper = 0;
  num.Numbers = 0;
  num.Symbols = 0;
  const bonus = {};
  bonus.Excess = 3;
  bonus.Upper = 4;
  bonus.Numbers = 5;
  bonus.Symbols = 5;
  bonus.Combo = 0;
  bonus.FlatLower = 0;
  bonus.FlatNumber = 0;
  let baseScore = 0, score = 0;
  const charPassword = value.split("");
  for (let i=0; i <charPassword.length; i++) {
    if (charPassword[i].match(/[A-Z]/g)) {num.Upper++;}
    if (charPassword[i].match(/[0-9]/g)) {num.Numbers++;}
    if (charPassword[i].match(/(.*[!,@,#,$,%,^,&,*,?,_,~])/)) {num.Symbols++;}
  }
  num.Excess = charPassword.length - minPasswordLength;

  if (num.Upper && num.Numbers && num.Symbols) {
    bonus.Combo = 25;
  } else if ((num.Upper && num.Numbers) || (num.Upper && num.Symbols) || (num.Numbers && num.Symbols)) {
    bonus.Combo = 15;
  }

  if (value.match(/^[\sa-z]+$/)) {
    bonus.FlatLower = -15;
  }

  if (value.match(/^[\s0-9]+$/)) {
    bonus.FlatNumber = -35;
  }

  // minPasswordLength was previously set to 8, but has been increased to 12
  //   to prevent a password that meets every requirement in the tooltip
  //   from displaying as "weak", which can not be submitted.
  //   To keep the same scoring logic, strongPasswordBonus accounts for the
  //   4 characters' worth of "bonus.Excess" points (3 each) that would be
  //   added to the final score of a 12 character password with minPasswordLength set to 8.
  let strongPasswordBonus = 0;
  if (minPasswordLength > 8) {
    strongPasswordBonus = (minPasswordLength - 8) * 3;
  }

  score = baseScore + (num.Excess*bonus.Excess) + (num.Upper*bonus.Upper) + (num.Numbers*bonus.Numbers) + (num.Symbols*bonus.Symbols) + bonus.Combo + bonus.FlatLower + bonus.FlatNumber + strongPasswordBonus;

  if (this.passwordFieldTarget.value === "") {
      const complexity = document.getElementById('complexity');
      const pass_strength = document.getElementById('pass_strength');
      complexity.className = '';
      complexity.classList.add('default');
      pass_strength.innerText = "";
    } else if (score<50) {
      pass_strength.innerText = "Weak";
      complexity.className = '';
      complexity.classList.add('weak');
    } else if (score>=50 && score<75) {
      complexity.className = '';
      complexity.classList.add('strong');
      pass_strength.innerText = "Average";
    } else if (score>=75 && score<100) {
      complexity.className = '';
      complexity.classList.add('stronger');
      pass_strength.innerText = "Strong";
    } else if (score>=100) {
      complexity.className = '';
      complexity.classList.add('strongest');
      pass_strength.innerText = "Secure";
    }
}

resetTooltips(items) {
  items.map(item => {
    document.querySelector(`.${item}`).classList.remove('fa-check');
    document.querySelector(`.${item}`).classList.add('fa-times');
    document.getElementById(`${item}`).style.color = '';
  })
}

checkMatch() {
  let password = this.passwordFieldTarget.value;
  let password_confirmation = this.passwordConfirmationFieldTarget.value;
  const pass_match = document.getElementById('pass_match');
  const pass_icon = document.getElementById('match_icon');
  if (password && password_confirmation) {
    pass_match.innerText = 'Match';
    if (password === password_confirmation) {
      pass_icon.innerHTML = '<i class="fas fa-check ml-2"></i>'
    } else {
      pass_icon.innerHTML = '<i class="fas fa-times ml-2"></i>'
    }
  } else {
    pass_match.innerText = '';
    pass_icon.innerHTML = '';
    pass_icon.innerHTML = '';
  }
}

validateEmail() {
  const email = this.usernameFieldTarget.value;
  let optionalemailField = document.getElementById('optionalEmail');
  if (this.isEmail(email)) {
    optionalemailField.classList.add('d-none');
  } else {
    optionalemailField.classList.remove('d-none');
  }
}

validateEmailFormat() {
  let email = this.optionalEmailTarget.value;
  let username = this.usernameFieldTarget.value;
  // if email field is blank or username field is blank, allow user to keyboard navigate through to sign in link or live chat widget
  if(email != '' || username != '') {
    if (!this.isEmail(email)) {
      Swal.fire({
        title: 'Invalid Email Entered',
        type: 'error',
        text: 'The email entered is not in a valid format, please check your entry and submit the information again.',
        onClose: () => {
          this.usernameFieldTarget.value = '';
        }
      });
      this.optionalEmailTarget.value = '';
    }
  }
}

isEmail(email) {
  //https://html.spec.whatwg.org/multipage/input.html#valid-e-mail-address
  return /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/i.test(email);
}

validatePassword() {
  let createButton = document.querySelector('.create-account-btn');
  let pwError = document.getElementById('pwError');
  let pwErrorMatch = document.getElementById('pwErrorMatch');
  let pwErrorStrength = document.getElementById('pwErrorStrength');

  if (!this.passwordsMatch()) {
    createButton.setAttribute('disabled', true);
    pwErrorMatch.classList.remove('d-none');
    pwErrorStrength.classList.add('d-none');
    pwError.classList.remove('d-none');
  } else if (!this.passwordIsStrong()) {
    createButton.setAttribute('disabled', true);
    pwErrorMatch.classList.add('d-none');
    pwErrorStrength.classList.remove('d-none');
    pwError.classList.remove('d-none');
  } else {
    createButton.removeAttribute('disabled');
    pwError.classList.add('d-none');
  }
}

passwordsMatch() {
  let password = this.passwordFieldTarget.value;
  let password_confirmation = this.passwordConfirmationFieldTarget.value;
  return password == password_confirmation;
}

passwordIsStrong() {
  const complexity = document.getElementById('complexity');
  return complexity.className != "weak";
}

preventEnterSubmission(event) {
  let submitButton = document.getElementById('submit-button');
  if(submitButton._focusedElement) {
    if (event.keyCode === 13 || event.code === "Enter") {
      event.preventDefault();
      event.stopPropagation();
    }
  }
}

checkRegistrationRules() {
  let registrationError = document.getElementsByClassName('registration-rules');

  if (registrationError.length) {
    //document.getElementsByClassName('registration-rules')[0].innerText = "Password didn't match with requirements.";
    setTimeout(function() {
      document.getElementById('user_password').focus();
    },300);
  }
}
}
