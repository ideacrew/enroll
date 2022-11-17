import { Controller } from 'stimulus';
import Swal from 'sweetalert2';

export default class extends Controller {
  static targets = [
    'passwordField',
    'usernameField',
    'passwordConfirmationField',
    'optionalEmail',
  ];

  createButton = undefined;
  rulesAreMet = false;

  connect() {
    // Equivalent to document ready
    this.getForms();
    this.checkRegistrationRules();

    // Initialize interactive elements
    this.createButton = document.querySelector('.create-account-btn');

    // Start form with create button disabled
    this.createButton.setAttribute('disabled', true);

    console.log('Hello from v2 javascript');
  }

  getForms() {
    // Fetch all the forms we want to apply custom Bootstrap validation styles to
    let forms = document.getElementsByClassName('needs-validation');
    // Loop over them and prevent submission
    Array.prototype.filter.call(forms, function (form) {
      form.addEventListener(
        'submit',
        function (event) {
          if (form.checkValidity() === false) {
            event.preventDefault();
            event.stopPropagation();
          }
          form.classList.add('was-validated');
        },
        false
      );
    });
  }

  emailTooltip() {
    this.hideTooltips();
    $('#user_oim_id').tooltip('show');
  }

  passwordTooltip() {
    const passwordHelper = `<p>Your password must:</p>
     <ul class="list-group pwHelper">
      <li id="length" class="invalid"><i class="fa fa-times mr-3 length"></i>Be at least 8 characters</li>
      <li id="longer" class="invalid"><i class="fa fa-times mr-3 longer"></i>Not be longer than 20 characters</li>
      <li id="lower" class="invalid"><i class="fa fa-times mr-3 lower"></i>Include at least one lowercase letter</li>
      <li id="upper" class="invalid"><i class="fa fa-times mr-3 upper"></i>Include at least one uppercase letter</li>
      <li id="number" class="invalid"><i class="fa fa-times mr-3 number"></i>Include at least one number</li>
      <li id="spec_char" class="invalid"><i class="fa fa-times mr-3 spec_char"></i>Include at least one special character ($!@%*&)</li>
      <li id="mtt" class="invalid"><i class="fa fa-times mr-3 mtt"></i>Cannot repeat any character more than 4 times</li>
      <li id="wh_space" class="invalid"><i class="fa fa-times mr-3 wh_space"></i>Not include blank spaces</li>
      <li id="nm_uid" class="invalid"><i class="fa fa-times mr-3 nm_uid"></i>Cannot contain username</li>
     </ul>
  `;
    this.hideTooltips();
    $('#user_password').attr('data-title', passwordHelper);
    $('#user_password').tooltip('show');
  }

  hideTooltips() {
    $('#user_oim_id').tooltip('hide');
    $('#user_password').tooltip('hide');
  }

  validateInput() {
    const password = this.passwordFieldTarget.value;
    // Password text must be present
    if (password.length > 0 && document.querySelector('.pwHelper')) {
      this.validateLength(password);
      this.validateNumber(password);
      this.validateSpecialCharacters(password);
      this.validateUpCase(password);
      this.validateLowerCase(password);
      this.validateRepeatedChar(password);
      this.validateWhiteSpace(password);
      this.validateUserIdMatch(password);
      this.passwordComplexity(password);
    } else if (password.length === 0) {
      // this.resetTooltips(['number', 'spec_char', 'mtt', 'wh_space', 'nm_uid']);
    }
  }

  resetIcons() {
    if (document.querySelector('.pwHelper')) {
      document.querySelector('.length').classList.remove('fa-check');
      document.getElementById('length').style.color = '';
      document.querySelector('.length').classList.add('fa-times');
      document.querySelector('.longer').classList.remove('fa-check');
      document.querySelector('.longer').classList.add('fa-times');
      document.getElementById('longer').style.color = '';
    }
  }

  validateLength(password) {
    if (password.length >= 8 && password.length < 20) {
      document.querySelector('.length').classList.add('fa-check');
      document.getElementById('length').style.color = '#bef470';
      document.querySelector('.longer').classList.add('fa-check');
      document.getElementById('longer').style.color = '#bef470';
    } else if (
      password.length < 8 &&
      this.usernameFieldTarget.value.length > 0
    ) {
      this.resetIcons();
    }
  }

  validateUpCase(password) {
    if (password.match(/[A-Z]/)) {
      document.querySelector('.upper').classList.add('fa-check');
      document.getElementById('upper').style.color = '#bef470';
    } else {
      document.querySelector('.upper').classList.remove('fa-check');
      document.querySelector('.upper').classList.add('fa-times');
      document.getElementById('upper').style.color = '';
    }
  }

  validateNumber(password) {
    if (password.match(/[0-9]/)) {
      document.querySelector('.number').classList.add('fa-check');
      document.getElementById('number').style.color = '#bef470';
    } else {
      document.querySelector('.number').classList.remove('fa-check');
      document.querySelector('.number').classList.add('fa-times');
      document.getElementById('number').style.color = '';
    }
  }

  validateSpecialCharacters(password) {
    if (password.match(/.[!,@,#,$,%,^,&,*,?,_,~,-,(,)]/)) {
      document.querySelector('.spec_char').classList.add('fa-check');
      document.getElementById('spec_char').style.color = '#bef470';
    } else {
      document.querySelector('.spec_char').classList.remove('fa-check');
      document.querySelector('.spec_char').classList.add('fa-times');
      document.getElementById('spec_char').style.color = '';
    }
  }

  validateLowerCase(password) {
    if (password.match(/[a-z]/)) {
      document.querySelector('.lower').classList.add('fa-check');
      document.getElementById('lower').style.color = '#bef470';
    } else {
      document.querySelector('.lower').classList.remove('fa-check');
      document.querySelector('.lower').classList.add('fa-times');
      document.getElementById('lower').style.color = '';
    }
  }

  validateRepeatedChar(password) {
    const max_repeats = 4;
    let pass_str = password;
    const chars = pass_str.split('');
    const cmap = {};

    if (password.length < 1) {
      document.querySelector('.mtt').classList.remove('fa-check');
      document.querySelector('.mtt').classList.add('fa-times');
      document.getElementById('mtt').style.color = '';
    }
    for (var i = 0; i < chars.length; i++) {
      if (!cmap.hasOwnProperty(chars[i])) cmap[chars[i]] = 0;
      cmap[chars[i]]++;
    }
    for (let p in cmap) {
      if (cmap[p] > max_repeats) {
        document.querySelector('.mtt').classList.remove('fa-check');
        document.querySelector('.mtt').classList.add('fa-times');
        document.getElementById('mtt').style.color = '';
      } else {
        document.querySelector('.mtt').classList.add('fa-check');
        document.getElementById('mtt').style.color = '#bef470';
      }
    }
  }

  validateWhiteSpace(password) {
    if (password.match(/\s/)) {
      document.querySelector('.wh_space').classList.add('fa-times');
      document.getElementById('wh_space').style.color = '';
    } else {
      document.querySelector('.wh_space').classList.add('fa-check');
      document.getElementById('wh_space').style.color = '#bef470';
    }
  }

  validateUserIdMatch(value) {
    if (
      this.usernameFieldTarget.value.length > 0 &&
      this.passwordFieldTarget.value.indexOf(this.usernameFieldTarget.value) >=
        0
    ) {
      document.querySelector('.nm_uid').classList.add('fa-times');
      document.getElementById('nm_uid').style.color = '';
    } else {
      document.querySelector('.nm_uid').classList.add('fa-check');
      document.getElementById('nm_uid').style.color = '#bef470';
    }
  }

  passwordComplexity(password) {
    const minPasswordLength = 8;
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
    let baseScore = 0,
      score = 0;
    const charPassword = password.split('');
    for (let i = 0; i < charPassword.length; i++) {
      if (charPassword[i].match(/[A-Z]/g)) {
        num.Upper++;
      }
      if (charPassword[i].match(/[0-9]/g)) {
        num.Numbers++;
      }
      if (charPassword[i].match(/(.*[!,@,#,$,%,^,&,*,?,_,~])/)) {
        num.Symbols++;
      }
    }
    num.Excess = charPassword.length - minPasswordLength;

    if (num.Upper && num.Numbers && num.Symbols) {
      bonus.Combo = 25;
    } else if (
      (num.Upper && num.Numbers) ||
      (num.Upper && num.Symbols) ||
      (num.Numbers && num.Symbols)
    ) {
      bonus.Combo = 15;
    }

    if (password.match(/^[\sa-z]+$/)) {
      bonus.FlatLower = -15;
    }

    if (password.match(/^[\s0-9]+$/)) {
      bonus.FlatNumber = -35;
    }

    score =
      baseScore +
      num.Excess * bonus.Excess +
      num.Upper * bonus.Upper +
      num.Numbers * bonus.Numbers +
      num.Symbols * bonus.Symbols +
      bonus.Combo +
      bonus.FlatLower +
      bonus.FlatNumber;

    if (password === '') {
      const complexity = document.getElementById('complexity');
      const pass_strength = document.getElementById('pass_strength');
      complexity.className = '';
      complexity.classList.add('default');
      pass_strength.innerText = '';
    } else if (score < 50) {
      pass_strength.innerText = 'Weak';
      complexity.className = '';
      complexity.classList.add('weak');
    } else if (score >= 50 && score < 75) {
      complexity.className = '';
      complexity.classList.add('strong');
      pass_strength.innerText = 'Average';
    } else if (score >= 75 && score < 100) {
      complexity.className = '';
      complexity.classList.add('stronger');
      pass_strength.innerText = 'Strong';
    } else if (score >= 100) {
      complexity.className = '';
      complexity.classList.add('strongest');
      pass_strength.innerText = 'Secure';
    }
  }

  resetTooltips(items) {
    items.map((item) => {
      document.querySelector(`.${item}`).classList.remove('fa-check');
      document.querySelector(`.${item}`).classList.add('fa-times');
      document.getElementById(`${item}`).style.color = '';
    });
  }

  checkMatch() {
    let password = this.passwordFieldTarget.value;
    console.log({ password: this.passwordFieldTarget.value });
    let password_confirmation = this.passwordConfirmationFieldTarget.value;
    const pass_match = document.getElementById('pass_match');
    const pass_icon = document.getElementById('match_icon');
    if (password && password_confirmation) {
      pass_match.innerText = 'Match';
      if (password === password_confirmation) {
        pass_icon.innerHTML = '<i class="fas fa-check ml-2"></i>';
      } else {
        pass_icon.innerHTML = '<i class="fas fa-times ml-2"></i>';
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
    if (!this.isEmail(email)) {
      Swal.fire({
        title: 'Invalid Email Entered',
        type: 'error',
        text: 'The email entered is not in a valid format, please check your entry and submit the information again.',
        onClose: () => {
          this.usernameFieldTarget.value = '';
        },
      });
      this.optionalEmailTarget.value = '';
    }
  }

  isEmail(email) {
    return /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))$/i.test(
      email
    );
  }

  comparePasswords() {
    let password = this.passwordFieldTarget.value;
    let password_confirmation = this.passwordConfirmationFieldTarget.value;
    let pwError = document.getElementById('pwError');

    if (password !== password_confirmation) {
      pwError.classList.remove('d-none');
    } else {
      pwError.classList.add('d-none');
    }
  }

  preventEnterSubmission(event) {
    if (event.keyCode === 13 || event.code === 'Enter') {
      event.preventDefault();
      event.stopPropagation();
    }
  }

  enableAccountCreation() {
    if (this.passwordsMatch && this.rulesAreMet) {
      this.createButton.removeAttribute('disabled');
    }
  }

  checkRegistrationRules() {
    let registrationError =
      document.getElementsByClassName('registration-rules');

    if (registrationError.length) {
      //document.getElementsByClassName('registration-rules')[0].innerText = "Password didn't match with requirements.";
      setTimeout(function () {
        document.getElementById('user_password').focus();
      }, 300);
    }
  }
}
