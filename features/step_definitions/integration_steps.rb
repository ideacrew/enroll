require 'watir'
load Rails.root + "db/seeds.rb"

Before "@watir" do
  @browser = Watir::Browser.new :chrome
end

After "@watir" do
  @browser.close
end

Given(/^I do not exist as a user$/) do
end

Given(/^I have an existing employee record$/) do
end

Given(/^I have an existing person record$/) do
end

When(/^I go to the employee account creation page$/) do
  @browser.goto("http://localhost:3000/")
  Watir::Wait.until(30) { @browser.a(:text => "Employee Portal").present? }
  sleep(1)
  @browser.a(:text => "Employee Portal").click
  Watir::Wait.until(30) { @browser.a(:text => "Create account").present? }
  sleep(1)
  @browser.a(:text => "Create account").click
end

When(/^I enter my new account information$/) do
  Watir::Wait.until(30) { @browser.text_field(:name => "user[password_confirmation]").present? }
  @browser.text_field(:name => "user[email]").set("trey.evans#{rand(100)}@dc.gov")
  @browser.text_field(:name => "user[password]").set("12345678")
  @browser.text_field(:name => "user[password_confirmation]").set("12345678")
  @browser.input(:value => "Create account").click
end

Then(/^I should be logged in$/) do
  Watir::Wait.until(30) { @browser.element(:text => /Welcome! You have signed up successfully./).present? }
  expect(@browser.element(:text => /Welcome! You have signed up successfully./).visible?).to be_truthy
end

When(/^I go to register as an employee$/) do
  expect(@browser.a(:text => "Continue").visible?).to be_truthy
  @browser.a(:text => "Continue").click
end

Then(/^I should see the employee search page$/) do
  Watir::Wait.until { @browser.text_field(:name => "person[first_name]").present? }
  expect(@browser.text_field(:name => "person[first_name]").visible?).to be_truthy
end

When(/^I enter the identifying info of my existing person$/) do
  @browser.text_field(:name => "person[first_name]").set("Jonathan")
  @browser.text_field(:name => "person[last_name]").set("Hall")
  @browser.text_field(:name => "person[date_of_birth]").set("10/12/1983")
  @browser.p(:text=> /Personal Information/).click
  @browser.text_field(:name => "person[ssn]").set("722991234")
  sleep(2)
  @browser.input(:value => "Search", :type => "submit").click
  sleep(3)
end

Then(/^I should see the matched employee record form$/) do
  expect(@browser.dd(:text => /Acme Inc\./).visible?).to be_truthy
  @browser.input(:value => /This is my employer/).click
  sleep(5)
end

When(/^I enter the personal infomation of my existing person$/) do
  @browser.text_field(:name => "person[phones_attributes][0][full_phone_number]").set("(111) 111-1111")
  @browser.text_field(:name => "person[emails_attributes][0][address]").set("aa@home.com")
  @browser.text_field(:name => "person[emails_attributes][1][address]").click
  sleep(2)
  @browser.input(:id => "continue-employer").click
end

Then(/^I should see the matched household information$/) do
  Watir::Wait.until(30) { @browser.p(:text => "Household Information").present? }
  expect(@browser.p(:text => /Household Information/).visible?).to be_truthy
end

When(/^I enter household information$/) do
  @browser.a(:class => "btn-green", :text => "Continue").click
end

Then(/^I should see the plan selection page$/) do
  Watir::Wait.until(30) { @browser.p(:text => "Select a Plan.").present? }
  expect(@browser.span(:text => /Selecting a plan can feel tricky/).visible?).to be_truthy
end

When(/^I enter filter in plan selection page$/) do
  @browser.a(:id => "select-plan-btn1", :text => "Continue").click
  Watir::Wait.until(30) { @browser.a(:text => "All Filters").present? }
  @browser.a(:text => "All Filters").click
  @browser.checkboxes(:class => "plan-type-selection-filter").first.set(true)
  @browser.button(:class => "apply-btn", :text => "Apply").click
end

Then(/^I should see the filter results$/) do
  expect(@browser.divs(class: "plan-row").select(&:visible?).count).to eq @browser.strongs(text: "HMO").select(&:visible?).count
end

When(/^I enter combind filter in plan selection page$/) do
  @browser.a(:text => "All Filters").click
  # HMO
  @browser.checkboxes(:class => "plan-type-selection-filter").first.set(true)
  # Nationwide
  @browser.checkboxes(class: "plan-metal-network-selection-filter").first.set(true)
  # Platinum
  @browser.checkboxes(class: "plan-metal-level-selection-filter").last.set(true)
  @browser.text_field(class: "plan-metal-deductible-from-selection-filter").set("$0")
  @browser.text_field(class: "plan-metal-deductible-to-selection-filter").set("$0")
  @browser.button(:class => "apply-btn", :text => "Apply").click
end

Then(/^I should see the combind filter results$/) do
  @browser.divs(class: "plan-row").select(&:visible?).each do |plan|
    expect(plan.text.include?("HMO")).to eq true
    expect(plan.text.include?("Nationwide")).to eq true
    expect(plan.text.include?("Platinum")).to eq true
    expect(plan.strong(text: "$0").visible?).to eq true
  end
end

When(/^I complete the matched employee form$/) do
  @browser.text_field(:name => "person[phones_attributes][0][full_phone_number]").set("5555555555")
  @browser.text_field(:name => "person[emails_attributes][0][address]").set("jhall@gmail.com")
  @browser.text_field(:name => "person[emails_attributes][1][address]").click
  @browser.input(:id => "continue-employer").click
  sleep(5)
end

Then(/^I should see the dependents page$/) do
  expect(@browser.p(:text => /Household Information/).visible?).to be_truthy
end

When(/^I click continue on the dependents page$/) do
  @browser.a(:text => "Continue", :href => /people\/select_plan/).click
  sleep(5)
end

Then(/^I should see the plan shopping page$/) do
    pending
end
