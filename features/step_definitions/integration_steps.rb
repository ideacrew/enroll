require 'watir'

Given(/^I do not exist as a user$/) do
end

Given(/^I have an existing employee record$/) do
end

Given(/^I have an existing person record$/) do
end

When(/^I go to the employee account creation page$/) do
  @browser = Watir::Browser.new :chrome, :switches => []
  @browser.goto("http://localhost:3000/")
  sleep(3)
  @browser.a(:text => "Employee Portal").click
  sleep(3)
  @browser.a(:text => "Create account").click
  sleep(3)
end

When(/^I enter my new account information$/) do
  @browser.text_field(:name => "user[email]").set("trey.evans@dc.gov")
  @browser.text_field(:name => "user[password]").set("12345678")
  @browser.text_field(:name => "user[password_confirmation]").set("12345678")
  @browser.input(:value => "Create account").click
  sleep(3)
end

Then(/^I should be logged in$/) do
  expect(@browser.element(:text => /Welcome! You have signed up successfully./).visible?).to be_truthy
end

When(/^I go to register as an employee$/) do
end

Then(/^I should see the employee search page$/) do
end

When(/^I enter the identifying info of my existing person$/) do
end

Then(/^I should see the matched employee record form$/) do
end
