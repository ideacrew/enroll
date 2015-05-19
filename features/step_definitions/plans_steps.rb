When(/^I enter the personal infomation of my existing person$/) do
  @browser.text_field(:name => "person[phones_attributes][0][full_phone_number]").set("(111) 111-1111")
  @browser.text_field(:name => "person[emails_attributes][0][address]").set("aa@home.com")
  @browser.text_field(:name => "person[emails_attributes][1][address]").click
  @browser.input(:id => "continue-employer").click
end

When(/^I click "(.*?)"$/) do |text|
  @browser.input(:value => text).click
end

Then(/^I should see the matched household information$/) do
  Watir::Wait.until(30) { @browser.h3(:text => "Personal Information").present? }
  expect(@browser.h3(:text => /Personal Information/).visible?).to be_truthy
end

When(/^I enter household information$/) do
  Watir::Wait.until(20) { @browser.text_field(:name => "person[phones_attributes][0][full_phone_number]").present? }
  @browser.text_field(:name => "person[phones_attributes][0][full_phone_number]").set("(111) 111-1111")
  @browser.text_field(:name => "person[emails_attributes][0][address]").set("aa@home.com")
  @browser.text_field(:name => "person[emails_attributes][1][address]").click
  @browser.input(id: 'continue-employer').click
  Watir::Wait.until(20) { @browser.a(:class => "btn-green", :text => "Continue").present? }
  @browser.a(:class => "btn-green", :text => "Continue").click
end

Then(/^I should see the plan selection page$/) do
  Watir::Wait.until(30) { @browser.input(:value => "Continue").present? }
  @browser.input(value: 'Continue').click
  Watir::Wait.until(30) { @browser.p(:text => "Select a Plan.").present? }
  expect(@browser.span(:text => /Selecting a plan can feel tricky/).visible?).to be_truthy
end

Then(/^I should see the filter results$/) do
  expect(@browser.divs(:class => "plan-row").select(&:visible?).count).to eq @browser.strongs(:text => "HMO").select(&:visible?).count
end


When(/^I select a plan in plan selection page$/) do
  @browser.as(:class => "select-btn", :text => "Select").select(&:visible?).first.click
end

Then(/^I should see the plan thankyou page$/) do
  Watir::Wait.until(30) { @browser.strong(:text => "Confirm Your Selection").present? }
  expect(@browser.p(:text => /Below is your current plan selection. Clicking confirm will enroll you and your family./).visible?).to be_truthy
end
