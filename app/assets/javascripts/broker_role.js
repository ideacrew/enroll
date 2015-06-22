$(function() {
  $('div[name=broker_signup_primary_tabs] > ').children().each( function() { 
    $(this).change(function(){
      filter = $(this).val();
      $('#' + filter + '_panel').siblings().empty().hide();
      $('#' + filter + '_panel').show();
      $.ajax({
        url: '/broker_roles/new.js',
        type: "GET",
        data : { 'filter': filter }
      });
    })
  })
})

$(document).on('change', "div[name=broker_agency_tabs] input[type='radio']", function() {
  filter = 'broker_role';
  agency_type = $(this).val();
  $('#' + agency_type + '_broker_agency_form').siblings().hide();
  $('#' + agency_type + '_broker_agency_form').show();
});

$(document).on('click', '.broker-agency-search a.search', function() {
  $('.broker-agency-search .result').empty();
  var broker_agency_id = $('select.broker_agency').val();
  if (broker_agency_id != undefined && broker_agency_id != ""){
    $(this).button('loading');
    $.ajax({
      url: '/broker_roles/search_broker_agency.js',
      type: "GET",
      data : { 'broker_agency_id': broker_agency_id }
    });
  };
});
