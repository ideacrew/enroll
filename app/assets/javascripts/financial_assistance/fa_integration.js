$(document).ready(function() {
  if ($("#origin_source").val() == "fa_application_edit_add_member")  {
    $('#household_info_add_member').click();
  }

  $("body").on("click", ".close_member_form", function () {
    $(".append_consumer_info").html("");
    $(".faa-row").removeClass('hide');
  });

  // Check for Eligibility Result response every "interval_time" seconds a total of "number_of_times" times.
  if (/wait_for_eligibility_response/.test(window.location.href)) {
    var number_of_times = 10;
    var interval_time = 2000;

    for (var i = 0; i < number_of_times; i++) {
      setTimeout(function () {
        $.ajax({
          type: "GET",
          data:{},
          url: window.location.href.replace(/wait_for_eligibility_response/, "check_eligibility_results_received"),
          success: function (response_received_flag) {
            if (response_received_flag == "true")
              // redirect to the existing eligibility_results page
              window.location = window.location.href.replace(/wait_for_eligibility_response/, "eligibility_results")
            else
              // redirect to error page
              window.location = window.location.href.replace(/wait_for_eligibility_response/, "eligibility_response_error")
          }
        });
      }, i * interval_time)
    }
  }

});