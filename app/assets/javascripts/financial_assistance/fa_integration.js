$(document).ready(function() {
  if ($("#origin_source").val() == "fa_application_edit_add_member")  {
    $('#household_info_add_member').click();
  }

  $("body").on("click", ".close_member_form", function () {
    $(".append_consumer_info").html("");
    $(".faa-row").removeClass('hide');
  });
});