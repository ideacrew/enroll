$('#qle-details .qle-form').addClass('hidden');
<% if @qualified_date %>
  $('#qle-details .success-info').removeClass('hidden');
  $('#qle-details .error-info').addClass('hidden');
  $('#qle-details .initial-info').addClass('hidden');
<% else %>
  $('#qle-details .error-info').removeClass('hidden');
  $('#qle-details .success-info').addClass('hidden');
  $('#qle-details .initial-info').addClass('hidden');
<% end %>

$('#qle-details .default-info').addClass('hidden');

// $('.add_new_family_member').click();
