
Then (/^Hbx Admin sees Families index$/) do
  expect(page).to have_text("Families")
end

When(/^Hbx Admin clicks on Families tab$/) do
  find(:xpath, "//li[contains(., '#{"Families"}')]", :wait => 10).click
  find(:xpath,'//*[@id="myTab"]/li[2]/ul/li[1]/a/span[1]', :wait => 10).trigger('click')
  wait_for_ajax 
end

Then(/^Hbx Admin should see an Actions link$/) do
  expect(page).to have_text("Actions")
end

When(/^Hbx Admin clicks on the Actions button$/) do
  find(:xpath,'//*[@id="dropdownMenu1"]').trigger('click')
end

Then(/^Hbx Admin should see an Enable \/ Disable link$/) do
  find_link('Enable / Disable').visible?
end

When(/^Hbx Admin clicks on the Enable \/ Disable link$/) do
  click_link "Enable / Disable"
end

Then(/^Hbx Admin should see the person record disabled$/) do
  wait_for_ajax(3)
  expect(page).to have_text("Disabled user John Smith1") 
end