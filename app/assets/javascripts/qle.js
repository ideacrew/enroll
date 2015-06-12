$(function () {
	$(document).on('click', 'a.qle-menu-item', function() {
		$('#qle-menu').hide();
		$('.qle-details-title').html($(this).html());
		$('#qle-details').removeClass('hidden');
	});

	$(document).on('click', '#qle-details .close-popup, #qle-details .cancel, #existing_coverage, #new_plan', function() {
		$('#qle-details').addClass('hidden');
		$('#qle-details .success-info, #qle-details .error-info').addClass('hidden');
		$('#qle-details .default-info').removeClass('hidden');

		$('#qle-menu').show();
	});

	/* QLE Date Validator */
	$(document).on('click', '#qle_submit', function() {
		if(check_qle_date()) {
			$('#qle_date').removeClass('input-error');
			$('#qle-input-info').html('Enter the date of the event.')
			get_qle_date();
		} else {
			$('#qle-input-info').html('Enter valid date here!');
			$('#qle_date').addClass('input-error');
		}
	});

	function check_qle_date() {
		var date_value = $('#qle_date').val();
		if(date_value == "" || isNaN(Date.parse(date_value)) || Date.parse(date_value) > Date.parse(new Date())) { return false; }
		return true;
	}

	function get_qle_date() {
		$.ajax({
			type: "GET",
			data:{date_val: $("#qle_date").val()},
			url: "/consumer_profiles/check_qle_date.js"
		});
	}
});