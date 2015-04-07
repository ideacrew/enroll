<% if @qualified_date %>
$('#qle_marriage_form').html('<p class="success-text"><strong>Success!</strong>You have created a special enrollment period.<br>Click continue go to the add your new family member and select your plan.</p><div class="text-center"><a href="#" class="btn btn-blue-2 btn-lg">Continue</a></div>');
<% else %>
$('#qle_marriage_form').html('<p class="error-text">The date you submitted does not qualify for special enrollment.<br>Please double check the date or contact DCHBX support 1-800-555-1212 option 1</p><div class="text-center"><a href="#" class="btn btn-blue-2 btn-lg">Back</a></div>');
<% end %>