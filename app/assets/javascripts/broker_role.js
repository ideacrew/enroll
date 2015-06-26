$(function() {
  applyBrokerTabClickHandlers();
});

function applyBrokerTabClickHandlers(){
  $('div[name=broker_agency_tabs] >').children().each( function() { 
    $(this).change(function(){
      filter = 'broker_role';
      agency_type = $(this).attr('value');
      $.ajax({
        url: '/broker_roles/new.js',
        type: "GET",
        data : { 'filter': filter, 'agency_type': agency_type }
      });
    })
  })
}

$(function() {
  $('ul[name=broker_signup_primary_tabs] > li > a').on('click', function() {
      filter = $(this).data('value');
      $.ajax({
        url: '/broker_roles/new.js',
        type: "GET",
        data : { 'filter': filter }
      });
  })
})

$(document).on('click', '.broker-agency-search a.search', function() {
  $('.broker-agency-search .result').empty();
  var broker_agency_search = $('input#agency_search').val();
  if (broker_agency_search != undefined && broker_agency_search != ""){
    $(this).button('loading');
    $('#person_broker_agency_id').val("");
    $.ajax({
      url: '/broker_roles/search_broker_agency.js',
      type: "GET",
      data : { 'broker_agency_search': broker_agency_search }
    });
  };
});

$(document).on('click', "a.select-broker-agency", function() {
  $('.result .form-border').removeClass("agency-selected");
  $('#person_broker_agency_id').val($(this).data('broker_agency_profile_id'));
  $(this).parents(".form-border").addClass("agency-selected");
});
