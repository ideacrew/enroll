$('#message_list_form').hide();
$('#show_message_form').show();
$('#show_message_form').html("<%= escape_javascript(render "shared/inboxes/form") %>");
$(".btn-danger").click(function(){
  $('#show_message_form').hide();
  $('#message_list_form').show();
});
