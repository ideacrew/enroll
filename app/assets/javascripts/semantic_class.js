// Adds semantic class to all input fields eg. interaction-field-control-person-first-name
function semantic_class() {
	$('input[type="text"], input[type="email"], input[type="password"], input[type="submit"]').each(function() {
		var element_id = $(this).attr('id');
		if(element_id) {
			console.log($(this));
			$(this).addClass('interaction-field-control-' + element_id.replace(/_/gi, '-'));
		}
	});

	// Adds semantic class to all a, submit
	$('a, button').each(function() {
		var element_id = $.trim($(this).text());

		if(element_id) {
			// console.log($.trim(element_id));
			$(this).addClass('interaction-click-control-' + element_id.toLowerCase().replace(/_| /gi, '-'));
		}
	});
}