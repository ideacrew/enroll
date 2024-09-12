import { Controller } from "stimulus"
import Rails from 'rails-ujs';

export default class extends Controller {

  static targets = ["threshold"]

  update() {
    let thresholdTarget = this.thresholdTarget;
    let threshold = thresholdTarget.value;
    let marketKind = $(thresholdTarget).parents('.qle-list-tab').data('market-kind');

    fetch('/exchanges/manage_sep_types/set_threshold', {
      method: 'PATCH',
      body: JSON.stringify({commonality_threshold: threshold, market_kind: marketKind}),
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': Rails.csrfToken()
      }
    })
    .then(response => response.json())
    .then(data => {
      $('#threshold-marker').detach().insertBefore($(`div[data-index='${threshold}']`));
      
      const successBanner =  $('#success-flash')
      const errorBanner = $('#error-flash')
      if (data['status'] == 'success') {
        successBanner.removeClass('hidden');
        errorBanner.addClass('hidden');
        var flashDiv = successBanner;
      } else {
        errorBanner.removeClass('hidden');
        successBanner.addClass('hidden');
        var flashDiv = errorBanner;
      }
    })
  }
}
