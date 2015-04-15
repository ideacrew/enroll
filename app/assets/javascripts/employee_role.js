function displayEmployeeRoleSearch() {
	$("#overlay").css("display", "none");
	$(".information").removeClass('hidden');
	$("a.name").css("padding-top", "30px");
	$(".disable-btn").css("display", "inline-block");
	$('.focus_effect:first').addClass('personaol-info-top-row');
	$('.focus_effect:first').removeClass('personaol-info-row');
	$('.sidebar a:first').addClass('style_s_link');
	$("#personal_info").css("display", "block");
	$(".search-btn-row").css("display", "block");
	$(".personal_info").css("display", "block");
	$(".start").hide();
}

$(function () {
  displayEmployeeRoleSearch();
});
