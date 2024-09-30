function enableBrokerApplicantFilters() {

  var url = '/exchanges/broker_applicants.js';

  if( $('#broker_agency_profile_id').length ) {
     url = $('#broker_agency_profile_id').attr("href") + ".js";
  }


  $('div[name=broker_applicants_tabs] > ').children().each( function() {
    $(this).change(function(){
      filter = $(this).val();
      $.ajax({
        url: url,
        type: "GET",
        data : { 'status': filter }
      });
    });
  });

  const filterInputs = document.querySelectorAll('#applicantsFilters input');
  const bs4 =  document.documentElement.dataset.bs4;

  filterInputs.forEach(input => {
    input.addEventListener('change', function(){
      var filter = $(this).val();
      $.ajax({
        url: url,
        type: "GET",
        data : { 'status': filter, 'bs4': bs4 }
      });
    });
  });

}
