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
  Watir::Wait.until(30) { @browser.p(:text => "Personal Information").present? }
  expect(@browser.p(:text => /Personal Information/).visible?).to be_truthy
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

When(/^I enter filter in plan selection page$/) do
  @browser.a(:id => "select-plan-btn1", :text => "Continue").click
  Watir::Wait.until(30) { @browser.a(:text => "All Filters").present? }
  @browser.a(:text => "All Filters").click
  @browser.checkboxes(:class => "plan-type-selection-filter").first.set(true)
  @browser.button(:class => "apply-btn", :text => "Apply").click
end

Then(/^I should see the filter results$/) do
  expect(@browser.divs(:class => "plan-row").select(&:visible?).count).to eq @browser.strongs(:text => "HMO").select(&:visible?).count
end

When(/^I enter combind filter in plan selection page$/) do
  @browser.a(:text => "All Filters").click
  # HMO
  @browser.checkboxes(:class => "plan-type-selection-filter").first.set(true)
  # Nationwide
  @browser.checkboxes(:class => "plan-metal-network-selection-filter").first.set(true)
  # Platinum
  @browser.checkboxes(:class => "plan-metal-level-selection-filter").last.set(true)
  @browser.text_field(:class => "plan-metal-deductible-from-selection-filter").set("$0")
  @browser.text_field(:class => "plan-metal-deductible-to-selection-filter").set("$0")
  @browser.button(:class => "apply-btn", :text => "Apply").click
end

Then(/^I should see the combind filter results$/) do
  @browser.divs(:class => "plan-row").select(&:visible?).each do |plan|
    expect(plan.text.include?("HMO")).to eq true
    expect(plan.text.include?("Nationwide")).to eq true
    expect(plan.text.include?("Platinum")).to eq true
    expect(plan.strong(text: "$0").visible?).to eq true
  end
end

When(/^I select a plan in plan selection page$/) do
  @browser.as(:class => "select-btn", :text => "Select").select(&:visible?).first.click
end

Then(/^I should see the plan thankyou page$/) do
  Watir::Wait.until(30) { @browser.strong(:text => "Confirm Your Selection").present? }
  expect(@browser.p(:text => /Below is your current plan selection. Clicking confirm will enroll you and your family./).visible?).to be_truthy
end
