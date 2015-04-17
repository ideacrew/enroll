function displayEmployeeRoleSearch() {
	$("#overlay").css("display", "none");
	$("a.name").css("padding-top", "30px");
	$(".disable-btn").css("display", "inline-block");
	$('.focus_effect:first').addClass('personal-info-top-row');
	$('.focus_effect:first').removeClass('personal-info-row');
	$('.sidebar a:first').addClass('style_s_link');
	$(".start").hide();
}

$(function () {
  displayEmployeeRoleSearch();
});
