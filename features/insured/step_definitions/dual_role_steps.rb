# frozen_string_literal: true

Given(/^a person exists with a user$/) do
  @dual_role_person = FactoryBot.create(
    :person,
    :with_consumer_role,
    first_name: 'Dual',
    last_name: 'Role'
  )

  FactoryBot.create(:user, person: @dual_role_person)
end

And(/^this person has a consumer role with failed or pending RIDP verification$/) do
  @dual_role_person.user.update_attributes(identity_verified_date: nil)
  @dual_role_person.consumer_role.move_identity_documents_to_outstanding
end

And(/^the last visited page is RIDP agreement$/) do
  @dual_role_person.consumer_role.update_attributes!(
    bookmark_url: "#{Rails.application.routes.url_helpers.root_url}insured/consumer_role/ridp_agreement"
  )
end

And(/^this person has an unapproved broker role and broker agency profile$/) do
  @broker_role = FactoryBot.create(:broker_role, person: @dual_role_person)
  site = FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, site_key: ::EnrollRegistry[:enroll_app].settings(:site_key).item)
  broker_agency_organization = FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, legal_name: 'First Legal Name', site: site)
  @broker_agency_profile = broker_agency_organization.broker_agency_profile
  @broker_agency_profile.update_attributes!(primary_broker_role_id: @broker_role.id)
  @broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: @broker_agency_profile.id)
end

And(/^the broker role is approved, broker agency staff is created and is associated to the broker agency profile$/) do
  @broker_role.approve!
  @dual_role_person.create_broker_agency_staff_role(benefit_sponsors_broker_agency_profile_id: @broker_agency_profile.id).broker_agency_accept!
  @broker_agency_profile.approve! if @broker_agency_profile.may_approve?
end

Given(/^broker_role_consumer_enhancement feature is enabled/) do
  enable_feature :broker_role_consumer_enhancement
end

Given(/^broker_role_consumer_enhancement feature is disabled/) do
  disable_feature :broker_role_consumer_enhancement
end

And(/^the Dual Role user logs into their account$/) do
  login_as(@dual_role_person.user, scope: :user)
end

And(/^lands on RIDP agreement page$/) do
  visit 'insured/consumer_role/ridp_agreement'
end

Then(/^the user will be able to see My Portals dropdown$/) do
  expect(page).to have_content('MY PORTALS')
end

Then(/^the user will not be able to see My Portals dropdown$/) do
  expect(page).not_to have_content('MY PORTALS')
end

And(/^the user clicks My Portals dropdown$/) do
  find('a', text: 'MY PORTALS', wait: 5).click
end

Then(/^the user will see My Insured Portal Link and My Broker Agency Portal Link$/) do
  expect(page).to have_text('MY INSURED PORTAL')
  expect(page).to have_text(@broker_agency_profile.legal_name.upcase)
end

And(/^the user clicks the Broker Agency Profile link with legal name$/) do
  click_link(@broker_agency_profile.legal_name, wait: 5)
end

Then(/^the user navigates to the Broker Agency Profile$/) do
  expect(page).to have_text(@broker_agency_profile.legal_name)
end

And(/^the user clicks the My Insured Portal link$/) do
  find_all('li', text: 'My Insured Portal'.upcase)[1].click
end

And(/^the user navigates to Consumer Role account to RIDP agreeement page$/) do
  expect(page).to have_text('Authorization and Consent')
end

Then(/^the user will be able to see My Broker Agency Portal Link$/) do
  expect(page).to have_text('MY BROKER AGENCY PORTAL')
end

And(/^the user clicks the Broker Agency Profile link$/) do
  find('a', text: 'MY BROKER AGENCY PORTAL', wait: 5).click
end

Then(/^the user does not see My Insured Portal Link$/) do
  expect(page).not_to have_content('MY PORTALS')
  expect(page).not_to have_text('MY INSURED PORTAL')
end
