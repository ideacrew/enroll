function displayEmployeeRoleSearch() {
	$("#overlay").css("display", "none");
	$("a.name").css("padding-top", "30px");
	$(".disable-btn").css("display", "inline-block");
	$('.focus_effect:first').addClass('personaol-info-top-row');
	$('.focus_effect:first').removeClass('personaol-info-row');
	$('.sidebar a:first').addClass('style_s_link');
	$(".start").hide();
}

$(function () {
  displayEmployeeRoleSearch();
});
