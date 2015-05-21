$(document).ready(function () {
	//This function adds semantic class to all input fields of type "text" eg. interaction-field-control-person-first-name
	$('input[type="text"], input[type="email"], input[type="password"]').each(function() {
		var element_id = $(this).attr('id');
		$(this).addClass('interaction-field-control-' + element_id.replace(/_/gi, '-'));
	});
});