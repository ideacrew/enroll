$(function() {

  $('#radio_existing_agency').click(function(){
    displayExistingAgencyForm()
  })

  $('#radio_broker').click(function(){
    $('#broker_agency_type').show();
    $('#person_broker_applicant_type').val('broker');
    if($('#radio_existing_agency').is(':checked')) {
      displayExistingAgencyForm()
    }
    else{
      displayNewAgencyForm()
    }
  })

  $('#radio_staff').click(function(){
    $('#person_broker_applicant_type').val('staff');
    $('#broker_agency_type').hide();
    $('#broker_npn_field').hide();
    displayExistingAgencyForm()
  })

  $('#radio_new_agency').click(function(){
    displayNewAgencyForm()
  })

  function displayNewAgencyForm(){
    $('#existing_broker_agency_form').hide();
    $('#new_broker_agency_form').show();
  }

  function displayExistingAgencyForm(){
    $('#new_broker_agency_form').hide();
    $('#existing_broker_agency_form').show(); 
  }
})