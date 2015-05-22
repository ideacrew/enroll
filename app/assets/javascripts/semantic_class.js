$(document).ready(function () {
	// Adds semantic class to all input fields eg. interaction-field-control-person-first-name
	$('input[type="text"], input[type="email"], input[type="password"]').each(function() {
		var element_id = $(this).attr('id');
		if(element_id) {
			$(this).addClass('interaction-field-control-' + element_id.replace(/_/gi, '-'));
		}
	});

	// Adds semantic class to all a, submit
});