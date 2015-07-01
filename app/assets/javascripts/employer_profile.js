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
    data = "<option value=''>SELECT RELATIONSHIP</option><option value='spouse'>Spouse</option><option value='domestic_partner'>Domestic partner</option><option value='child_under_26'>Child</option><option value='disabled_child_26_and_over'>Disabled child</option>'";
  }else{
    data = "<option value=''>SELECT RELATIONSHIP</option><option value='spouse'>Spouse</option><option value='domestic_partner'>Domestic partner</option><option value='child_26_and_over'>Child</option><option value='disabled_child_26_and_over'>Disabled child</option>'";
  }
  $(target).html(data);
  $(target).selectric('refresh');
});
