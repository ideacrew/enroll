document.addEventListener("turbolinks:load", function() {
  // Check for Eligibility Result response every "interval_time" seconds a total of "number_of_times" times.
  if (/wait_for_primary_response/.test(window.location.href)) {
    var i = 1;
    var number_of_times = 10;
    var interval_time = 2000;
    var repeater = setInterval(function () {
      if ( i < number_of_times) {
        $.ajax({
          type: "GET",
          data:{},
          url: window.location.href.replace(/wait_for_primary_response/, "check_primary_response_received"),
          success: function (response_received_flag) {
            if (response_received_flag == "true"){
              // redirect to the existing eligibility_results page
              window.location = window.location.href.replace(/wait_for_primary_response/, "primary_response")
            }
          }
        });
        i += 1;
      } else {
        clearInterval(repeater);
        if ( i > 9 ){
          window.location = window.location.href.replace(/wait_for_primary_response/, "service_unavailable")
        }
      }
    }, interval_time);
  }
});