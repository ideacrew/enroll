Then(/^there are (\d+) preloaded (.*?) user accounts$/) do |num, status|
  (0...num.to_i).each do |int|
    user = FactoryGirl.create(:user, :with_family)
    user.update_lockable if status.eql?('locked')
  end
end

Then(/^Hbx Admin should see Unlock\/Lock Account link$/) do
  find_link('Unlock / Lock Account').visible?
end

Then(/^Hbx Admin clicks on Unlock\/Lock Account link$/) do
  click_link('Unlock / Lock Account')
end

When 'Admin confirm the popup' do
  sleep 1
  page.driver.browser.accept_confirm
  wait_for_ajax
  sleep 1
end

Then(/^the locked user should be in the list$/) do
  page.all('table.effective-datatable tbody tr').last.should(have_content('Locked'))
end
