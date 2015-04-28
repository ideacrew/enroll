$(function() {

  $("input#family_all").change(function(){
    $("tr.terminated_true").show();
    $("tr.terminated_false").show();
    $('.confirm-terminate-wrapper').hide();
  });

  $("input#family_waived").change(function(){
    $("tr.terminated_true").hide();
    $("tr.terminated_false").hide();
    $('.confirm-terminate-wrapper').hide();
  });

  $("input#terminated_yes").change(function(){
    $("tr.terminated_true").show();
    $("tr.terminated_false").hide();
    $('.confirm-terminate-wrapper').hide();
  });

  $("input#terminated_no").change(function(){
    $("tr.terminated_false").show();
    $("tr.terminated_true").hide();
    $('.confirm-terminate-wrapper').hide();
  });

  $("input#terminated_no").trigger("change");
  
  $( ".show_confirm" ).click(function() {
    var el_id = $(this).attr('id');
    $( "td." + el_id ).toggle();
    $( "#confirm-terminate-2" ).hide();
  });
  
  $(document).ready(function(){
    $('.delete_confirm').click(function(){
      var element_id = $(this).attr('id');
      var termination_date = $(this).siblings().val();
      var link_to_delete = $(this).data('link');
      $.ajax({
        type: 'get',
        datatype : 'js',
        url: link_to_delete,
        data: {termination_date: termination_date},
        success: function(response){
          if(response=="true") {
            $('.'+element_id).remove();
          } else {
            
          }
        },
        error: function(response){
          Alert("Sorry, something went wrong");
        }
      });
    });
  });
  
})
