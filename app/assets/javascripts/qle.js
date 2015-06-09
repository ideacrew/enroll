$(function () {
	$('a.qle-menu-item').on('click', function() {
		$('#qle-menu').hide();
		$('.qle-details-title').html($('.qle-menu-item').html());
		$('#qle-details').removeClass('hidden');
	});

	$('#qle-details .close-popup').on('click', function() {
		$('#qle-details').addClass('hidden');
		$('#qle-menu').show();
	});
});