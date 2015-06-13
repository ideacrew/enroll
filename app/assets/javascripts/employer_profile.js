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

  $("input#terminated_no").trigger("change");
  
  $(document).on('click', ".show_confirm", function(){
    var el_id = $(this).attr('id');
    $( "td." + el_id ).toggle();
    $( "#confirm-terminate-2" ).hide();
  });
  
  $(document).on('click', ".delete_confirm", function(){
      //var element_id = $(this).attr('id');
      var termination_date = $(this).siblings().val();
      var link_to_delete = $(this).data('link');
      $.ajax({
        type: 'get',
        datatype : 'js',
        url: link_to_delete,
        data: {termination_date: termination_date},
        success: function(response){
          if(response=="true") {
            //$('.'+element_id).remove();
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
  
})
