import { Controller } from "stimulus"
import axios from 'axios'

export default class extends Controller {

  showSsn(event) {
    const target = $(event.target);
    const personId = target.data('id');
    const familyId = target.data('family-id');
    const subjectType = target.data('type');

    if (personId == 'temp') {
      this.showSsnInput(personId);
    } else {
      axios({
        method: 'GET',
        url: `/insured/family_members/${personId}/show_ssn`,
        params: {
          family_id: familyId,
          type: subjectType
        },
        headers: {
          'X-CSRF-Token': document.querySelector("meta[name=csrf-token]").content
        }
      }).then((response) => {
        if (response.data.status == 200) {
          let payload = response.data.payload;
          $(`.ssn-input-${personId}`).val(payload);

          this.showSsnInput(personId);
        } else {
          console.log("Unauthorized.");
        }
      }).catch(() => {
        console.log('Error retrieving info');
      })
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
  }

  showSsnInput(personId) {
    $(`.ssn-input-${personId}`).removeClass('hidden');
    $(`.ssn-facade-${personId}`).addClass('hidden');
    $(`.ssn-eye-on-${personId}`).removeClass('hidden');
    $(`.ssn-eye-off-${personId}`).addClass('hidden');

    $(`.ssn-eye-on-${personId}`).focus();
  }
}