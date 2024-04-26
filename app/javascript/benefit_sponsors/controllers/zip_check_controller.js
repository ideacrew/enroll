import { Controller } from "stimulus"
import axios from 'axios'

export default class extends Controller {
  static targets = ['countySelect']

  initialize() {

  }

  zipChange(event) {
   if (this.countySelectTarget) {
    axios({
      method: 'POST',
      url: '/benefit_sponsors/profiles/registrations/counties_for_zip_code',
      data: { zip_code: event.currentTarget.value },
      headers: {
        'X-CSRF-Token': document.querySelector("meta[name=csrf-token]").content
      }
    }).then((response) => {
      if (response.data.length >= 1) {
        this.countySelectTarget.removeAttribute('disabled')
        this.countySelectTarget.options.length = 0;
        event.target.parentElement.classList.remove('was-validated')
        event.target.setCustomValidity("")
        let optionValues = JSON.parse(this.countySelectTarget.dataset.options);

        for (let option of optionValues) {
          if (response.data.includes(option)) {
            let newOption = document.createElement("option")
            newOption.text = option;
            newOption.value = option;
            this.countySelectTarget.add(newOption)
          }
        }

      } else {
        this.countySelectTarget.setAttribute('disabled', true);
        this.countySelectTarget.options.length = 0;
        let newOption = document.createElement("option")
        newOption.text = null;
        newOption.value = null;
        this.countySelectTarget.add(newOption)
        event.target.parentElement.classList.add('was-validated')
        event.target.setCustomValidity("")
      }
      if (this.countySelectTarget.parentElement.className == 'selectric-hide-select') {
        if( $.isFunction( $.fn.selectric ) ) {
          $(this.countySelectTarget).selectric('refresh')
        }
      }
    })
  }}
}
