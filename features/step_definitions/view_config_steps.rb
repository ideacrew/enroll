Given(/^the user is on the Main Page$/) do
  visit exchanges_hbx_profiles_root_path
  expect(current_path).to eq exchanges_hbx_profiles_root_path
end

Then(/^the user will see the Config tab$/) do
  find('.dropdown-toggle', :text => "Admin").trigger 'click'
  expect(page).to have_content('Config')
end


Then(/^the user will not see the Config tab$/) do
  find('.dropdown-toggle', :text => "Admin").trigger 'click'
  expect(page).to_not have_content('Config')
end