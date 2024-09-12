import { Controller } from "stimulus"
import Sortable from "sortablejs"
import Rails from 'rails-ujs';

var bs4 = document.documentElement.dataset.bs4 == "true";
export default class extends Controller {
	connect() {
		this.sortable = Sortable.create(this.element, {
			onEnd: this.end.bind(this),
			filter: '#threshold-marker'
		})
	}

	end(event) {
		let index = event.item.dataset.index
		let rowId = event.item.dataset.id
		let prevPosition = parseInt(index) + 1
		let market_kind = bs4 ? $(event.item).parents('.qle-list-tab').data('market-kind') : event.item.dataset.market_kind;
		let data = []
		var cards = document.querySelectorAll('.card.mb-4')
		var textContent = event.item.textContent
		data = [...cards].reduce(function(data, card, index) { return [...data, { id: card.dataset.id, position: index + 1 }] }, [])

		for (var i = 0; i < data.length; i++) {
			if (data[i]['id'] === rowId && prevPosition === parseInt(data[i]['position'])){
				return;
			}
		}

		fetch('update_list',{
			method: 'PATCH',
			body: JSON.stringify({market_kind: market_kind, sort_data: data}),
			headers: {
								'Content-Type': 'application/json',
								'X-CSRF-Token': Rails.csrfToken()
								}
		})
		.then(response => response.json())
  		.then(data => {
			if (bs4) {
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
			setTimeout(function() {
				flashDiv.addClass('hidden');
			}, 3500);
		})
	}
}

$( document ).ready(function() {
	$( "#sort_notification_msg .close" ).click(function() {
		$("#sort_notification_msg").hide();
	});
});
