import { Controller } from "stimulus"
import axios from 'axios'

export default class extends Controller {
  static targets = ['countySelect']
  
  initialize() {
    document.getElementById('kindSelect').value = "primary";
  }

  zipChange(event) {
    axios({
      method: 'POST',
      url: 'counties_for_zip_code',
      data: { zip_code: event.currentTarget.value },
      headers: {
        'X-CSRF-Token': document.querySelector("meta[name=csrf-token]").content
      }
    }).then((response) => {
      if (response.data.length >= 1) {
        event.target.parentElement.classList.remove('was-validated')
        event.target.setCustomValidity("")
        this.countySelectTarget.childNodes.forEach((option) => {
          if (option.value == "") return // skip blank
          if (response.data.includes(option.value))
            option.disabled = false
          else
            option.disabled = true
        })
        if (response.data.length == 1) // if there's only 1 county select it
          this.countySelectTarget.querySelector(`option[value=${response.data[0]}]`).selected = true
      } else {
        event.target.parentElement.classList.add('was-validated')
        event.target.setCustomValidity("Not an MA zip.")
      }
    })
  }
}
