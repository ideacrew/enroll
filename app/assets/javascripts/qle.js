$(function () {
	$('a.qle-menu-item').on('click', function() {
		$('#qle-menu').hide();
		$('.qle-details-title').html($(this).html());
		$('#qle-details').removeClass('hidden');
	});

	$('#qle-details .close-popup').on('click', function() {
		$('#qle-details').addClass('hidden');
		$('#qle-menu').show();
	});

	/* QLE Date Validator */
	$('#qle_submit').on('click', function() {
		if(check_qle_date()) {
			$('#qle_date').removeClass('input-error');
			get_qle_date();
		} else {
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

// function validate_qle(qle_date_field) {
// 	if($(qle_date_field).val() == '') {
// 		$(qle_date_field).css('border', '1px solid #ff0000');
// 		return false;
// 	} else {
// 		$(qle_date_field).css('border', '1px solid #cccccc');
// 		return true;
// 	}
// }