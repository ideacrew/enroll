import { Controller } from "stimulus"
import axios from 'axios'

export default class extends Controller {

  showSsn(event) {
    const target = $(event.target);
    const personId = target.data('id');
    const familyId = target.data('family-id');

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
    if ($(`.ssn-input-${personId}`).is('input')) {
      $(`.ssn-input-${personId}`).val(payload);
    } else {
      console.log('I am updating correctly');
      $(`.ssn-input-${personId}`).text(payload);
    }
  }

  hideSsn(event) {
    const target = $(event.target);
    const personId = target.data('id');

    $(`.ssn-input-${personId}`).addClass('hidden');
    $(`.ssn-facade-${personId}`).removeClass('hidden');
    $(`.ssn-eye-on-${personId}`).addClass('hidden');
    $(`.ssn-eye-off-${personId}`).removeClass('hidden');

    $(`.ssn-eye-off-${personId}`).focus();
    if ($(`.ssn-input-${personId}`).data('admin-can-enable')) {
      $(`.ssn-input-${personId}`)?.prop('disabled', true);
    }
  }

  showSsnInput(personId) {
    $(`.ssn-input-${personId}`).removeClass('hidden');
    $(`.ssn-facade-${personId}`).addClass('hidden');
    $(`.ssn-eye-on-${personId}`).removeClass('hidden');
    $(`.ssn-eye-off-${personId}`).addClass('hidden');

    $(`.ssn-eye-on-${personId}`).focus();
    if ($(`.ssn-input-${personId}`).data('admin-can-enable')) {
      $(`.ssn-input-${personId}`)?.prop('disabled', false);
    }
  }
}