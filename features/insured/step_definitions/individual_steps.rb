# frozen_string_literal: true

When(/^Individual market is not under open enrollment period$/) do
  visit "/"
  find(HomePage.consumer_family_portal_btn).click
  FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)
  FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual")
  FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date_and_first_month, market_kind: "individual")
  BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
  r_id = BenefitMarkets::Products::Product.all.where(title:  "IVL Test Plan Bronze")[1].id.to_s
  BenefitMarkets::Products::Product.all.where(title:  "IVL Test Plan Bronze")[0].update_attributes!(renewal_product_id: r_id)
end

And(/there exists (.*) with active individual market role and verified identity$/) do |named_person|
  consumer_with_verified_identity(named_person)
end

And(/(.*) logged into the consumer portal$/) do |named_person|
  person = people[named_person]
  person_rec = Person.where(first_name: person[:first_name], last_name: person[:last_name]).first
  login_as person_rec.user
  visit 'families/home'
end

Then(/^(.*) clicks continue from qle$/) do |_name|
  expect(page).to have_content "Based on the information you entered, you may be eligible to enroll now but there is limited time"
  click_button "Continue"
end

Then(/(.*) clicks Back to my account button$/) do |_name|
  find('.interaction-click-control-back-to-my-account').click
end

Then(/(.*) should land on Home page and should see Shop for Plans Banner$/) do |_name|
  sleep 2
  expect(page).to have_content(/You are eligible to enroll or change coverage through/)
end

When(/(.*) click the "(.*?)" in qle carousel/) do |_name, qle_event|
  expect(page).to have_content(qle_event, wait: 10)
  click_link qle_event.to_s
end

Then(/(.*) should see family members page and clicks continue/) do |_name|
  expect(page).to have_content l10n('family_information').to_s
  find('#dependent_buttons .interaction-click-control-continue', :wait => 5).click
end

When(/^(.*) selects a past qle date$/) do |_name|
  expect(page).to have_content "Married"
  fill_in "qle_date", :with => (TimeKeeper.date_of_record - 5.days).strftime("%m/%d/%Y")
  click_link((TimeKeeper.date_of_record - 5.days).day)
  within '#qle-date-chose' do
    click_link "CONTINUE"
  end
end
