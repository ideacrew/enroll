  $(document).on('change', "input#family_all", function(){
    $("tr.terminated_true").show();
    $("tr.terminated_false").show();
    $('.confirm-terminate-wrapper').hide();
  });

  $(document).on('change', "input#family_waived", function(){
    $("tr.terminated_true").hide();
    $("tr.terminated_false").hide();
    $('.confirm-terminate-wrapper').hide();
  });

  $(document).on('change', "input#terminated_yes", function(){
    $("tr.terminated_true").show();
    $("tr.terminated_false").hide();
    $("tr.rehired").hide();
    $('.confirm-terminate-wrapper').hide();
  });

  $(document).on('change', "input#terminated_no", function(){
    $("tr.terminated_false").show();
    $("tr.terminated_true").hide();
    $("tr.rehired").hide();
    $('.confirm-terminate-wrapper').hide();
  });
  
  $(document).on('click', ".show_confirm", function(){
    var el_id = $(this).attr('id');
    $( "td." + el_id ).toggle();
    $( "#confirm-terminate-2" ).hide();
    return false;
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

$(document).on('page:update', function(){
  $("input#terminated_no").trigger("change");
});
