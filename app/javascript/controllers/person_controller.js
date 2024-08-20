import { Controller } from "stimulus"
import axios from 'axios'

export default class extends Controller {
  connect() {
    document.addEventListener("keydown", this.handleKeyDown);
  } 

  disconnect() {
    document.removeEventListener("keydown", this.handleKeyDown);
  } 
  
  handleKeyDown(event) {
    event.preventDefault();
    if (event.key === 'Enter' || event.key === ' ') {
      event.target.click();
    }
  }

  showSsn(event) {
    event.stopImmediatePropagation();
    let target = event.target;
    let personId = target.getAttribute('data-id');
    let familyId = target.getAttribute('data-family-id');

    if (personId == 'temp') {
      this.showSsnInput(personId);
    } else {
      axios({
        method: 'GET',
        url: `/insured/family_members/${personId}/show_ssn`,
        params: {
          family_id: familyId
        },
        headers: {
          'X-CSRF-Token': document.querySelector("meta[name=csrf-token]").content
        }
      }).then((response) => {
        if (response.data.status == 200) {
          let payload = response.data.payload;
          this.populateHtmlElement(personId, payload);

          this.showSsnInput(personId);
        } else {
          console.log("Unauthorized.");
        }
      }).catch(() => {
        console.log('Error retrieving info');
      })
    }
  }

  populateHtmlElement(personId, payload) {
    let ssnInputElement = document.querySelector(`.ssn-input-${personId}`);

    if (ssnInputElement.tagName === 'Input') {
      ssnInputElement.value = payload;
    } else {
      ssnInputElement.textContent = payload;
    }
  }

  hideSsn(event) {
    const target = event.target;
    const personId = target.getAttribute('data-id');
  
    document.querySelector(`.ssn-input-${personId}`).classList.add('hidden');
    document.querySelector(`.ssn-facade-${personId}`).classList.remove('hidden');
    document.querySelector(`.ssn-eye-on-${personId}`).classList.add('hidden');
    document.querySelector(`.ssn-eye-off-${personId}`).classList.remove('hidden');
  
    document.querySelector(`.ssn-eye-off-${personId}`).focus();
    const ssnInput = document.querySelector(`.ssn-input-${personId}`);
    if (ssnInput.getAttribute('data-admin-can-enable') !== null) {
      ssnInput.disabled = true;
    }
  }
  
  showSsnInput(personId) {
    document.querySelector(`.ssn-input-${personId}`).classList.remove('hidden');
    document.querySelector(`.ssn-facade-${personId}`).classList.add('hidden');
    document.querySelector(`.ssn-eye-on-${personId}`).classList.remove('hidden');
    document.querySelector(`.ssn-eye-off-${personId}`).classList.add('hidden');
  
    document.querySelector(`.ssn-eye-on-${personId}`).focus();
    const ssnInput = document.querySelector(`.ssn-input-${personId}`);
    if (ssnInput.getAttribute('data-admin-can-enable') !== null) {
      ssnInput.disabled = false;
    }
  }
}