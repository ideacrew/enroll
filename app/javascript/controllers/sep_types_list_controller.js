import { Controller } from "stimulus"
import Sortable from "sortablejs"

var bs4 = document.documentElement.dataset.bs4 == "true";

// Manages the sorting and commonality threshold clamping for the SEP types list.
export default class extends Controller {

  static targets = ["marketTab", "thresholdInput", "qleList"]

  get marketKind() {
    return this.marketTabTarget.id;
  }

  /**
  * Create the managers used to handle update list requests.
  */
  initialize() {
    this.orderManager = new UpdateOrderManager(this.marketKind, this.qleListTarget);
    if (this.hasThresholdInputTarget) {
      this.thresholdManager = new UpdateThresholdManager(this.marketKind, this.qleListTarget, this.thresholdInputTarget);
    }
  }

  /**
  * Configure the order manager to handle sorting the QLE list.
  */
	connect() {
    this.orderManager.configureSortable();
	}

  /**
  * Update the threshold in the threshold manager.
  */
  setThreshold() {
    this.thresholdManager.set();
  }
}

// Base manager used to handle update list requests and response banners.
class UpdateListManager {

  constructor(marketKind) {
    this.marketKind = marketKind;
  }

  /**
   * Perform a PATCH request to update the QLE list and shows the response banner.
   * @param {Object} body The request body containing the list update data.
   * @param {String} bannerDescription The message to use in the legacy response banner subheader.
   * @returns {Bool} The success status of the request.
   */
  async updateList(body, bannerDescription) {
    body.market_kind = this.marketKind;
		const response = await fetch('update_list', {
      method: 'PATCH',
      body: JSON.stringify(body),
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name=csrf-token]").content
      }
    });

    let data = await response.json();
    let isSuccess = data["status"] === "success";
    this.showBanner(isSuccess, data["message"], bannerDescription);

    return isSuccess;
  }

  /**
   * Show or hide the respective response banner.
   * @param {boolean} isSuccess The success status of the request.
   * @param {string} bannerTitle The message to use in the legacy response banner header.
   * @param {string} bannerDescription The message to use in the legacy response banner subheader.
   */
  showBanner(isSuccess, bannerTitle, bannerDescription) {
    if (bs4) {
      const successBanner = $('#success-flash');
      const errorBanner = $('#error-flash');
      successBanner.toggleClass('hidden', !isSuccess)
      errorBanner.toggleClass('hidden', isSuccess)
      var flashDiv = isSuccess ? successBanner : errorBanner;
    } else {
      var flashDiv = $("#sort_notification_msg");
      var flashHeader = flashDiv.find(".toast-header");
      flashDiv.show();

      flashDiv.removeClass("success").removeClass("error");
      flashDiv.toggleClass("success", isSuccess).toggleClass("error", !isSuccess);
      flashHeader.removeClass("success").removeClass("error");
      flashHeader.toggleClass("success", isSuccess).toggleClass("error", !isSuccess);

      flashHeader.find("strong").text(bannerTitle);

      var flashBody = flashDiv.find(".toast-body");
      if (bannerDescription) {
        flashBody.removeClass("hidden").text(bannerDescription);
      } else {
        flashBody.addClass("hidden");
      }
    }

    setTimeout(function() {
      flashDiv.addClass('hidden');
    }, 3500);
  }
}

// Manages the sorting of the SEP types list.
class UpdateOrderManager extends UpdateListManager {

  constructor(marketKind, qleListTarget) {
    super(marketKind);
    this.qleListTarget = qleListTarget;
  }

  /**
  * Initialize the sortable library and set the endDrag callback.
  */
  configureSortable() {
		this.sortable = Sortable.create(this.qleListTarget, {
			onEnd: this.endDrag.bind(this),
			filter: "#threshold-marker"
		});
  }

  /**
  * Handle updating the sort order for a QLE list.
  * Performs the PATCH request and shows the response banner.
  */
	endDrag(event) {
    let card = event.item;
    let originalPosition = parseInt(card.dataset.index);

    let cards = $(this.qleListTarget).find('.card').get();
    if (cards[originalPosition].dataset.id === card.dataset.id) { // If the card was not moved, do not sort the list
      return;
    }

    let enumeratedCards = [...cards.entries()];
    for (const [index, card] of enumeratedCards) {
      card.dataset.index = index;
      card.dataset.ordinal_position = index + 1;
    }

    let sortData = enumeratedCards.map((entry) => { return { id: entry[1].dataset.id, position: entry[0] + 1 } });
    super.updateList({sort_data: sortData}, event.item.textContent);
	}
}

// Manages the commonality threshold input and marker for the SEP types list.
class UpdateThresholdManager extends UpdateListManager {

  constructor(marketKind, qleListTarget, thresholdInputTarget) {
    super(marketKind);
    this.thresholdInputTarget = thresholdInputTarget;
    this.qleList = $(qleListTarget);
  }

  /**
  * Handle updating the commonality threshold for a QLE list.
  * Performs the PATCH request, then updates the threshold marker element and shows the banner based on the response.
  */
  set() {
    let threshold = this.thresholdInputTarget.value;

    super.updateList({commonality_threshold: threshold})
      .then(isSuccess => {
        if (isSuccess) {
          this.thresholdInputTarget.dataset.initialValue = threshold;

          // move the threshold marker to the new threshold index or hide it if out of bounds
          let thresholdMarker = this.qleList.find('#threshold-marker').removeClass('hidden');
          let newBoundaryQLE = this.qleList.find(`.card:eq(${threshold})`);
          if (newBoundaryQLE.length) {
            thresholdMarker.detach().insertBefore(newBoundaryQLE);
          } else {
            thresholdMarker.addClass('hidden');
          }
        } else {
          this.thresholdInputTarget.value = this.thresholdInputTarget.dataset.initialValue;
        }
      })
  }
}

if (!bs4) {
  $( document ).ready(function() {
    $( "#sort_notification_msg .close" ).click(function() {
      $("#sort_notification_msg").hide();
    });
  });
}
