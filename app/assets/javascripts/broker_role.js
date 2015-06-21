$(function() {
  $('div[name=broker_signup_primary_tabs] > ').children().each( function() { 
    $(this).change(function(){
      filter = $(this).val();
      $('#' + filter + '_panel').siblings().hide();
      $('#' + filter + '_panel').show();
      $.ajax({
        url: '/broker_roles/new.js',
        type: "GET",
        data : { 'filter': filter }
      });
    })
  })
})

$(function() {
  $('div[name=broker_agency_tabs] > ').children().each( function() { 
    $(this).change(function(){
      filter = 'broker_role';
      agency_type = $(this).val();
      $('#' + agency_type + '_broker_agency_form').siblings().hide();
      $('#' + agency_type + '_broker_agency_form').show();
      $.ajax({
        url: '/broker_roles/new.js',
        type: "GET",
        data : { 'filter': filter, 'agency_type': agency_type }
      });
    })
  })
})