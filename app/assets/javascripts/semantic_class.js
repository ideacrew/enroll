function semantic_class() {
	// Adds semantic class to all input fields eg. interaction-field-control-person-first-name
	$('input[type="text"], input[type="email"], input[type="password"]').each(function() {
		var element_id = $.trim($(this).attr('id'));

		if(element_id) {
			$(this).addClass('interaction-field-control-' + element_id.toLowerCase().replace(/_| /gi, '-'));
		}
	});

	// Adds semantic class to all a, submit eg. interaction-click-control-login
	$('a, button, input[type="submit"]').each(function() {

		if($(this).is('input[type="submit"]')) {
			var element_id = $.trim($(this).val());
		} else {
			var element_id = $.trim($(this).text());
		}

		if(element_id) {
			$(this).addClass('interaction-click-control-' + element_id.toLowerCase().replace(/[_&]| /gi, '-'));
		}
	});

	// Adds semantic class to all 'select' top levels
	$('select').each(function() {
		var element_id = $.trim($(this).attr('id'));

		if(element_id) {
			$(this).addClass('interaction-choice-control-' + element_id.toLowerCase().replace(/_| /gi, '-'));
			$('#' + element_id + ' option').each(function(index) {
				$(this).addClass('interaction-choice-control-' + element_id.toLowerCase().replace(/_| /gi, '-') + '-' + index);
			});
			$('select').on('selectric-init', function(element){
				$('.selectric').addClass('interaction-choice-control-' + element_id.toLowerCase().replace(/_| /gi, '-'));
				$('.selectric-items li').each(function() {
					var index = $(this).data("index");
					$(this).addClass('interaction-choice-control-' + element_id.toLowerCase().replace(/_| /gi, '-') + '-' + index);
				});
			});
		}
	});

	// Adds semantic class to all radio buttons and check boxes eg. interaction-choice-control-value-male
	$('input[type="radio"], input[type="checkbox"]').each(function() {
		var element_id = $.trim($(this).attr('id'));

		if(element_id) {
			$(this).addClass('interaction-choice-control-value-' + element_id.toLowerCase().replace(/_| /gi, '-'));
		}
	});
}