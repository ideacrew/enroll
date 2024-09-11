import { Controller } from "stimulus"
import Rails from 'rails-ujs';

export default class extends FlashableController {

  static targets = ["threshold"]

  update() {
    const threshold = this.thresholdTarget.value;

    function showBanner(isSuccessful) { super.showBanner(isSuccessful) };
    fetch('/exchanges/manage_sep_types/set_threshold', {
      method: 'PATCH',
      body: JSON.stringify({commonality_threshold: threshold}),
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': Rails.csrfToken()
      }
    })
    .then(response => response.json())
    .then(data => {
      $('#threshold-marker').detach().insertBefore($(`div[data-index='${threshold}']`));
      showBanner(true);
    })
  }
}


class FlashableController extends Controller {
  showBanner(isSuccessful) {
    const banners = {success: $('#success-flash'), error: $('#error-flash')}
    banners[isSuccessful ? 'success' : 'error'].removeClass('hidden');
    banners[isSuccessful ? 'error' : 'success'].addClass('hidden');
  }
}