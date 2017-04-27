function getEvents(event) {
  if (event == "system_event") {
  	$.ajax({
      type: 'get',
      datatype: 'js',
      url: '/exchanges/scheduled_events/get_system_events',
      //data: {f; f,},
      success: function (response) {
        $('#scheduled_event').show();
        $('#scheduled_event').html(response);
      }
    });
  }else if (event == "holiday") {
    $.ajax({
      type: 'get',
      datatype: 'js',
      url: '/exchanges/scheduled_events/get_holiday_events',
      //data: {f: f,},
      success: function (response) {
        $('#scheduled_event').show();
        $('#scheduled_event').html(response);
      }
    });
  }else {
  	$.ajax({
      type: 'get',
      datatype: 'js',
      url: '/exchanges/scheduled_events/no_events',
      success: function (response) {
        $('#scheduled_event').show();
        $('#scheduled_event').html(response);
      }
    });
  }
}