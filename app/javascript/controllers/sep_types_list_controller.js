import { Controller } from "stimulus"
import Sortable from "sortablejs"
import Rails from 'rails-ujs';

var bs4 = document.documentElement.dataset.bs4 == "true";

// Manages the sorting and commonality threshold clamping for the SEP types list.
export default class extends Controller {

  static targets = ["marketTab", "thresholdInput", "qleList"]

  // Lifecycle

	connect() {
		this.sortable = Sortable.create(this.qleListTarget, {
			onEnd: this.endDrag.bind(this),
			filter: "#threshold-marker"
		})
	}

  // Actions

  /** 
  * Handle updating the sort order for a QLE list.
  * Performs the patch request and shows the response banner.
  */
	endDrag(event) {
		let index = event.item.dataset.index
		let rowId = event.item.dataset.id
		let prevPosition = parseInt(index) + 1
		let data = []
		var cards = document.querySelectorAll('.card.mb-4')
		var textContent = event.item.textContent
		data = [...cards].reduce(function(data, card, index) { return [...data, { id: card.dataset.id, position: index + 1 }] }, [])

		for (var i = 0; i < data.length; i++) {
			if (data[i]['id'] === rowId && prevPosition === parseInt(data[i]['position'])){
				return;
			}
		}

    this.updateList({sort_data: data})
  		.then(data => {
			if (bs4) {
        this.showBanner(data['status'] === "success");
			} else {
				var flashDiv = $("#sort_notification_msg");
				flashDiv.show()
				if (data['status'] === "success") {
					flashDiv.addClass("success")
					flashDiv.removeClass("error")
					flashDiv.find(".toast-header").addClass("success")
					flashDiv.find(".toast-header").removeClass("error")
				} else {
					flashDiv.addClass("error")
					flashDiv.removeClass("success")
					flashDiv.find(".toast-header").addClass("error")
					flashDiv.find(".toast-header").removeClass("success")
				}
				flashDiv.find(".toast-header strong").text(data['message'])
				flashDiv.find(".toast-body").text(textContent)
			}
		})
	}

  /** 
  * Handle updating the commonality threshold for a QLE list.
  * Performs the patch request, then updates the threshold marker element and shows the banner based on the response.
  */
  updateThreshold() {
    let thresholdInputTarget = this.thresholdInputTarget;
    let threshold = thresholdInputTarget.value;

    this.updateList({commonality_threshold: threshold})
      .then(data => {
        let isSuccess = data['status'] === 'success';
        if (isSuccess) {
          thresholdInputTarget.dataset.initialValue = threshold;
          this.showBanner(true);

          // move the threshold marker to the new threshold index or hide it if out of bounds
          let qleList = $(this.qleListTarget);
          let thresholdMarker = qleList.find('#threshold-marker').removeClass('hidden');
          let newBoundaryQLE = qleList.find(`.card:eq(${threshold})`);
          if (newBoundaryQLE.length) {
            thresholdMarker.detach().insertBefore(newBoundaryQLE);
          } else {
            thresholdMarker.addClass('hidden');
          }
        } else {
          thresholdInputTarget.value = thresholdInputTarget.dataset.initialValue;
          this.showBanner(false);
        }
      })
  }

  // Shared helpers

  /**
   * Perform a PATCH request to update the sort order of the QLE list.
   * @param {Object} body The request body containing the updated sort order data.
   * @returns {Promise} The fetch request promise.
   */
  async updateList(body) {
    body.market_kind = this.marketTabTarget.id; // TODO: figure out legacy
		const response = await fetch('update_list', {
      method: 'PATCH',
      body: JSON.stringify(body),
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': Rails.csrfToken()
      }
    });
    return await response.json();
  }

  /**
   * Show or hide the respective response banner.
   * @param {boolean} isSuccess The success status of the request.
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

$( document ).ready(function() {
	$( "#sort_notification_msg .close" ).click(function() {
		$("#sort_notification_msg").hide();
	});
});
