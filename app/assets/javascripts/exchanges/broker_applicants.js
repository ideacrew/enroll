function enableBrokerApplicantFilters() {
  $('div[name=broker_applicants_tabs] > ').children().each( function() {
    $(this).change(function(){
      filter = $(this).val();
      $.ajax({
        url: '/exchanges/broker_applicants.js',
        type: "GET",
        data : { 'status': filter }
      });
    })
  })
}