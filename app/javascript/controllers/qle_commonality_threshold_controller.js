import { Controller } from "stimulus"
import Rails from 'rails-ujs';

export default class extends Controller {

  static targets = ["threshold"]

  update() {
    let thresholdTarget = this.thresholdTarget;
    let threshold = thresholdTarget.value;
    let marketKind = $(thresholdTarget).parents('.qle-list-tab').data('market-kind');

    fetch('update_list', {
      method: 'PATCH',
      body: JSON.stringify({commonality_threshold: threshold, market_kind: marketKind}),
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': Rails.csrfToken()
      }
    })
    .then(response => response.json())
    .then(data => {
      let isSuccess = data['status'] == 'success';
      if (isSuccess) {
        this.updateThresholdMarker(marketKind, threshold);
        this.showBanner(true);
      } else {
        thresholdTarget.value = thresholdTarget.dataset.initialValue;
        this.showBanner(false);
      }
    })
  }

  /**
   * Handle updating the threshold marker element by moving it after the updated threshold index, or hiding it if the new index is out of bounds.
   * @param {integer} threshold The updated index of the commonality threshold to move the marker to.
   * @param {string} marketKind The market kind of the QLE list to update the threshold marker for.
   */
  updateThresholdMarker(marketKind, threshold) {
    let thresholdMarker = $('#threshold-marker').show();
    let newBoundaryQLE = $(`#${marketKind} .qle-list > .card:eq(${threshold})`);
    if (newBoundaryQLE.length) {
      thresholdMarker.detach().insertBefore(newBoundaryQLE);
    } else {
      thresholdMarker.hide();
    }
  }

  /**
   * Show or hide the respective response banner.
   * @param {boolean} isSuccess The success status of the threshold update request.
   */
  showBanner(isSuccess) {
    const successBanner =  $('#success-flash');
    const errorBanner = $('#error-flash');
    successBanner.toggleClass('hidden', !isSuccess)
    errorBanner.toggleClass('hidden', isSuccess)
    var flashDiv = isSuccess ? successBanner : errorBanner;

    setTimeout(function() {
      flashDiv.addClass('hidden');
    }, 3500);
  }
}
