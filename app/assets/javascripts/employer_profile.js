$(function() {
  $('div[name=employee_family_tabs] > ').children().each( function() {
    $(this).change(function(){
      filter = $(this).val();
      search = $("#census_employee_search input#employee_name").val();
      $('#employees_' + filter).siblings().hide();
      $('#employees_' + filter).show();
      $.ajax({
        url: $('span[name=employee_families_url]').text() + '.js',
        type: "GET",
        data : { 'status': filter, 'employee_name': search },
        crossDomain: true,
        xhrFields: {
          withCredentials: true
        }
      });
    })
  })
})

$(document).on('click', ".show_confirm", function(){
  var el_id = $(this).attr('id');
  $( "td." + el_id ).toggle();
  $( "#confirm-terminate-2" ).hide();
  return false
});

$(document).on('click', ".delete_confirm", function(){
  var termination_date = $(this).closest('div').find('input').val();
  var link_to_delete = $(this).data('link');
  $.ajax({
    type: 'get',
    datatype : 'js',
    url: link_to_delete,
    data: {termination_date: termination_date},
    success: function(response){

        window.location.reload();

    },
    error: function(response){
      Alert("Sorry, something went wrong");
    }
  });
});

$(document).on('click', ".rehire_confirm", function(){
  var element_id = $(this).attr('id');
  var rehiring_date = $(this).siblings().val();
  var link_to_delete = $(this).data('link');
  $.ajax({
    type: 'get',
    datatype : 'js',
    url: link_to_delete,
    data: {rehiring_date: rehiring_date}
  });
});

$(document).on('change', '.dependent_info input.dob-picker', function(){
  var element = $(this).val().split("/");
  year = parseInt(element[2]);
  month = parseInt(element[0]);
  day = parseInt(element[1]);
  var mydate = dchbx_enroll_date_of_record();
  mydate.setFullYear(year + 26,month-1,day);
  var target = $(this).parents('.dependent_info').find('select');
  selected_option_index = $(target).get(0).selectedIndex

  if (mydate > dchbx_enroll_date_of_record()){
    data = "<option value=''>SELECT RELATIONSHIP</option><option value='spouse'>Spouse</option><option value='domestic_partner'>Domestic partner</option><option value='child_under_26'>Child</option>";
  }else{
    data = "<option value=''>SELECT RELATIONSHIP</option><option value='spouse'>Spouse</option><option value='domestic_partner'>Domestic partner</option><option value='child_26_and_over'>Child</option>";
  }
  $(target).html(data);
  $(target).prop('selectedIndex', selected_option_index).selectric('refresh');
});

$(function() {
  $("#publishPlanYear .close").click(function(){
    location.reload();
  });
  setProgressBar();
})

function setProgressBar(){

    // ignore this call by returning if no presense of progress-wrapper and employer-dummy classes
    if($('.progress-wrapper.employer-dummy').length == 0) {
      return;
    }



  maxVal = parseInt($('.progress-val .pull-right').data('value'));
  dividerVal = parseInt($('.divider-progress').data('value'));
  currentVal = parseInt($('.progress-bar').data('value'));
  percentageDivider = dividerVal/maxVal * 100;
  percentageCurrent = currentVal/maxVal * 100;

  $('.progress-bar').css({'width': percentageCurrent + "%"});
  $('.divider-progress').css({'left': (percentageDivider - 1) + "%"});

  barClass = currentVal < dividerVal ? 'progress-bar-danger' : 'progress-bar-success';
  $('.progress-bar').addClass(barClass);

  if(maxVal == 0){
    $('.progress-val strong').html('');
  }

  if(dividerVal == 0){
    $('.divider-progress').html('');
  }

  if(currentVal == 0){
    $('.progress-current').html('');
  }
}

$(document).on('click', '#census_employee_search_clear', function() {
  $('form#census_employee_search input#employee_name').val('');
  $("form#census_employee_search").submit();
})

$(document).on('change', '#address_info .office_kind_select select', function() {
  if ($(this).val() == 'mailing') {
    $(this).parents('fieldset').find('#phone_info input.area_code').attr('required', false);
    $(this).parents('fieldset').find('#phone_info input.phone_number7').attr('required', false);
  };
  if ($(this).val() == 'primary' || $(this).val() == 'branch'){
    $(this).parents('fieldset').find('#phone_info input.area_code').attr('required', true);
    $(this).parents('fieldset').find('#phone_info input.phone_number7').attr('required', true);
  };
})

function checkPhone(textbox) {
  var phoneRegex = /^\d{3}-\d{4}$/;
  if (textbox.value == '') {
    textbox.setCustomValidity('Please fill out this phone number field.');
  } else if(!phoneRegex.test(textbox.value)){
    textbox.setCustomValidity('please enter a valid phone number.');
  } else {
    textbox.setCustomValidity('');
  }
  return true;
}

function checkZip(textbox) {
  var phoneRegex = /^\d{5}$/;
  if (textbox.value == '') {
    textbox.setCustomValidity('Please fill out this zipcode field.');
  } else if(!phoneRegex.test(textbox.value)){
    textbox.setCustomValidity('please enter a valid zipcode.');
  } else {
    textbox.setCustomValidity('');
  }
  return true;
}

function checkAreaCode(textbox) {
  var phoneRegex = /^\d{3}$/;
  if (textbox.value == '') {
    textbox.setCustomValidity('Please fill out this area code field.');
  } else if(!phoneRegex.test(textbox.value)){
    textbox.setCustomValidity('please enter a valid area code.');
  } else {
    textbox.setCustomValidity('');
  }
  return true;
}

  //toggling of divs that show plan details (view details)
  $('.nav-toggle').click(function(){
    var collapse_content_selector = $(this).attr('href');
    var toggle_switch = $(this);
    $(collapse_content_selector).slideToggle('fast', function(){
      if($(this).css('display')=='none'){
        toggle_switch.html('View Details <i class="fa fa-chevron-down fa-lg">');
      }else{
        toggle_switch.html('Hide Details <i class="fa fa-chevron-up fa-lg">');
      }
    });
  });
