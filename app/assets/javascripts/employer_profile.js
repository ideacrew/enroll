$(function() {
  $('div[name=employee_family_tabs] > ').children().each( function() {
    $(this).change(function(){
      filter = $(this).val();
      $('#employees_' + filter).siblings().hide();
      $('#employees_' + filter).show();
      $.ajax({
        url: $('span[name=employee_families_url]').text() + '.js',
        type: "GET",
        data : { 'status': filter }
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
  var termination_date = $(this).siblings().val();
  var link_to_delete = $(this).data('link');
  $.ajax({
    type: 'get',
    datatype : 'js',
    url: link_to_delete,
    data: {termination_date: termination_date},
    success: function(response){
      if(response=="true") {
        window.location.reload();
      } else {

      }
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
  var mydate = new Date();
  mydate.setFullYear(year + 26,month-1,day);
  var target = $(this).parents('.dependent_info').find('select');

  if (mydate > new Date()){
    data = "<option value=''>SELECT RELATIONSHIP</option><option value='spouse'>Spouse</option><option value='domestic_partner'>Domestic partner</option><option value='child_under_26'>Child</option>";
  }else{
    data = "<option value=''>SELECT RELATIONSHIP</option><option value='spouse'>Spouse</option><option value='domestic_partner'>Domestic partner</option><option value='child_26_and_over'>Child</option>";
  }
  $(target).html(data);
  $(target).selectric('refresh');
});

$(function() {
  $("#publishPlanYear .close").click(function(){
    location.reload();
  });
  setProgressBar();
})

function setProgressBar(){
  if($('.form-border .progress-wrapper').length == 0)
    return;

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
