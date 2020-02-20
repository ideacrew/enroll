Then(/^Hbx Admin should see search box$/) do
  wait_for_ajax
  page.find("input[type='search']").visible?
end

When(/^he enters an broker agency name and clicks on the search button$/) do
  broker_organization_legal_name = broker_organization.legal_name
  page.find("input[type='search']").set(broker_organization_legal_name)
end

Then(/^he should see the one result with the agency name$/) do
  wait_for_ajax
  broker_organization_legal_name = broker_organization.legal_name
  expect(page).to have_content(broker_organization_legal_name)
end

And(/^Hbx Admin clicks on (.*?)$/) do |tab_name|
  target_dropdown = page.all('a').detect { |a| a.text == tab_name }
  target_dropdown.click
  wait_for_ajax
end
