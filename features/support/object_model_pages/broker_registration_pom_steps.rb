# frozen_string_literal: true

And(/broker with a specific NPN already exists/) do
  # Must satisfy this
  # Person.where("broker_role.npn" => npn).any?
  person = FactoryBot.build(:person)
  person.build_broker_role(
    npn: EnrollRegistry.feature_enabled?(:allow_alphanumeric_npn) ? BrokerRegistration.alphanumeric_npn : BrokerRegistration.alphabetic_npn,
    provider_kind: 'broker'
  ).save!
end

When(/a Primary Broker visits the HBX Broker Registration form POM/) do
  visit '/'
  find(HomePage.broker_registration_btn, wait: 10).click
end

Then(/Primary Broker should see the New Broker Agency form POM/) do
  expect(page).to have_css(BrokerRegistration.broker_registration_form)
end

Then(/Primary Broker should see the NPN already taken message/) do
  expect(page).to have_content(
    l10n(
      "broker_agencies.profiles.npn_taken_error",
      main_web_address: EnrollRegistry[:enroll_app].setting(:main_web_address).item,
      site_short_name: EnrollRegistry[:enroll_app].setting(:short_name).item,
      website_url: EnrollRegistry[:enroll_app].setting(:website_url).item,
      contact_center_short_number: EnrollRegistry[:enroll_app].setting(:contact_center_short_number).item,
      contact_center_tty_number: EnrollRegistry[:enroll_app].settings(:contact_center_tty_number).item
    )
  )
end

When(/Primary Broker enters personal information POM/) do
  fill_in BrokerRegistration.first_name, with: 'This is a POM'
  fill_in BrokerRegistration.last_name, with: 'example'
  fill_in BrokerRegistration.broker_dob, with: '02/02/1989'
  fill_in BrokerRegistration.email, with: 'pomexample@gmail.com'
  if EnrollRegistry.feature_enabled?(:allow_alphanumeric_npn)
    # State allows Alphanumeric
    fill_in BrokerRegistration.npn, with: BrokerRegistration.alphanumeric_npn
    # Assures the javascript didn't block the full NPN
    input = page.all('input').detect { |input_element| input_element[:id] == 'inputNPN' }
    expect(input.value).to eq(BrokerRegistration.alphanumeric_npn)
  else
    fill_in BrokerRegistration.npn, with: BrokerRegistration.alphabetic_npn
  end
end

And(/Primary Broker enters broker agency information POM/) do
  # There are a few market kinds
  # maybe make this flexible
  fill_in BrokerRegistration.legal_name, with: "Broker test pom"
  fill_in BrokerRegistration.dba, with: "Broker test"
  select "Individual & Family Marketplace ONLY", from: BrokerRegistration.practice_area_dropdown
  select "English", from: BrokerRegistration.select_languages
  find(BrokerRegistration.accept_new_client_checkbox).click
  fill_in BrokerRegistration.address, with: "123 test"
  select "Primary", from: BrokerRegistration.kind_dropdown
  fill_in BrokerRegistration.city, with: "Washington"
  select "DC", from: BrokerRegistration.state_dropdown
  fill_in BrokerRegistration.zip, with: "20001"
  fill_in BrokerRegistration.area_code, with: "202"
  fill_in BrokerRegistration.number, with: "2678765"
  find(BrokerRegistration.create_broker_agency_btn).click
end

Then(/Primary Broker should see the registration submitted successful message/) do
  sleep 10
  expect(page).to have_content(BrokerRegistration.registration_submitted_succesful_message)
end

And(/HBX Admin clicks the Approve Broker button POM$/) do
  find(BrokerAgencyStaffRegistration.approve_broker_btn).click
end