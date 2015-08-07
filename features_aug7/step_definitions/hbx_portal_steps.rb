

When(/^I visit the HBX portal to sign in$/) do
  @browser.goto("http://localhost:3000/")
  screenshot("hbx_portal_start")
  @browser.a(text: /HBX Portal/).wait_until_present
  @browser.a(text: /HBX Portal/).click
end

When(/^I sign in with valid Admin data$/) do	
  @browser.input(value: /Sign in/).wait_until_present
  user = FactoryGirl.create(:user)
  user.build_person(first_name: "John", last_name: "Doe", ssn: "111000999", dob: "10/10/1985")
  user.save

  @browser.text_field(name: "user[email]").set('admin@dc.gov')
  @browser.text_field(name: "user[password]").set('password')
  screenshot("hbx_portal_sign_in")
  @browser.input(value: /Sign in/).click
end

Then(/^Toolbar is visible$/) do
  expect(@browser.span(class: 'home-icon').visible?).to be_truthy
end

When(/^I select the tab (.+)$/) do |tab_title|
  @browser.a(text: tab_title ).click
  sleep 1
end

Then(/^I should see the header (.+)$/) do |tab_title|
  expect(@browser.h3(text: tab_title).visible?).to be_truthy
end


