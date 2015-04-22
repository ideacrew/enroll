Given(/^I haven't signed up as an HBX user$/) do
end

When(/^I visit the Employer portal$/) do
  @browser.goto("http://localhost:3000/")
  Watir::Wait.until(30) { @browser.a(:text => "Employer Portal").present? }
  sleep(1)
  @browser.a(:text => "Employer Portal").click
  Watir::Wait.until(30) { @browser.a(:text => "Create account").present? }
  sleep(1)
  @browser.a(:text => "Create account").click
end

And(/^I sign up with valid user data$/) do
  Watir::Wait.until(30) { @browser.text_field(:name => "user[password_confirmation]").present? }
  @browser.text_field(:name => "user[email]").set("trey.evans#{rand(100)}@dc.gov")
  @browser.text_field(:name => "user[password]").set("12345678")
  @browser.text_field(:name => "user[password_confirmation]").set("12345678")
  @browser.input(:value => "Create account").click
end

Then(/^I should see a successful sign up message$/) do
  Watir::Wait.until(30) { @browser.element(:text => /Welcome! You have signed up successfully./).present? }
  expect(@browser.element(:text => /Welcome! You have signed up successfully./).visible?).to be_truthy
end

And(/^I should see an initial form to enter information about my Employer and myself$/) do
  expect(@browser.button(:name=>"commit").visible?).to be_truthy
  expect(@browser.button.value == "Create").to be_truthy
  @browser.button(:name=>"commit").click
end

Given(/^I have signed up previously through consumer, broker agency or previous visit to the Employer portal with email (.+)$/) do |email|
end

When(/^I visit the Employer portal to sign in$/) do
  @browser.goto("http://localhost:3000/")
  Watir::Wait.until(30) { @browser.a(:text => "Employer Portal").present? }
  sleep(1)
  @browser.a(:text => "Employer Portal").click
end

And(/^I sign in with valid user data with email (.+) and password (.+)$/) do |email, password|
  Watir::Wait.until(30) { @browser.input(:value => "Sign in").present? }
  user = FactoryGirl.create(:user)
  @browser.text_field(:name => "user[email]").set(user.email)
  @browser.text_field(:name => "user[password]").set(user.password)
  @browser.input(:value => "Sign in").click
end

Then(/^I should see a successful sign in message$/) do
  Watir::Wait.until(30) { @browser.text.include?("Signed in successfully.") }
  expect(@browser.text.include?("Signed in successfully.")).to be_truthy
end

And(/^I should see an initial form with a fieldset for Employer information, including: legal name, DBA, fein, entity_kind, broker agency, URL, address, and phone$/) do
  pending
end

And(/^I should see a second fieldset to enter my name and email$/) do
  pending
end

And(/^My user data from existing the fieldset values are prefilled using data from my existing account$/) do
  pending
end
