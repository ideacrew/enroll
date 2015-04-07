<% if @qualified_date %>
  $('#qle_marriage_form .success-info').removeClass('hidden');
  $('#qle_marriage_form .error-info').addClass('hidden');
  $('#qle_marriage_form .initial-info').addClass('hidden');
<% else %>
  $('#qle_marriage_form .error-info').removeClass('hidden');
  $('#qle_marriage_form .success-info').addClass('hidden');
  $('#qle_marriage_form .initial-info').addClass('hidden');
<% end %>

$('.add_success').click(function(){
  $('#family-tab').click();
});

$('.add_new_family_member').click();

$('.marriage_back').click(function() {
  $('#qle_marriage_form .initial-info').removeClass('hidden');
  $('#qle_marriage_form .error-info').addClass('hidden');
  $('#qle_marriage_form .success-info').addClass('hidden');
});
