module VerificationUser
  def user(*traits)
    attributes = traits.extract_options!
    @user ||= FactoryBot.create :user, *traits, attributes
  end
end
World(VerificationUser)

Then(/^Individual click continue button$/) do
  find('.btn', text: 'CONTINUE').click
end

Then(/^I should see Documents link$/) do
  expect(page).to have_content "Documents"
end

When(/^.+ clicks on Documents link$/) do
  expect(page).to have_content "Documents"
  click_link "Documents"
end

Given(/^I should see page for documents verification$/) do
  expect(page).to have_content "Documents We Accept"
  expect(page).to have_content('Social Security Number')
  find('.btn', text: 'Documents We Accept').click
  expect(page).to have_content('DC Residency')
  find_link('https://dmv.dc.gov/page/proof-dc-residency-certifications').visible?
  new_window = window_opened_by { click_link 'https://dmv.dc.gov/page/proof-dc-residency-certifications' }
  switch_to_window new_window
end

Given(/^a consumer exists$/) do
  user :with_consumer_role
end

Given(/^the consumer is logged in$/) do
  login_as user
end

Then(/^the consumer visits verification page$/) do
  visit verification_insured_families_path
  find(".interaction-click-control-documents", wait: 5).click
end

When(/^the consumer should see documents verification page$/) do
  expect(page).to have_content('We verify the information you give us using electronic data sources. If the data sources do not match the information you gave us, we need you to provide documents to prove what you told us.')
  expect(page).to have_content "Documents We Accept"
  expect(page).to have_content('Social Security Number')
end

When(/^the consumer is completely verified$/) do
  user.person.consumer_role.import!(OpenStruct.new({:determined_at => Time.now, :vlp_authority => "hbx"}))
end

When(/^the consumer is completely verified from curam$/) do
  user.person.consumer_role.update_attributes(OpenStruct.new({:determined_at => Time.now, :vlp_authority => 'curam'}))
  user.person.consumer_role.import!
end

Then(/^verification types have to be visible$/) do
  expect(page).to have_content('Social Security Number')
  expect(page).to have_content('Citizenship')
end

Then(/^verification types should display as verified state$/) do
  expect(page).to have_content('Social Security Number')
  expect(page).to have_content('Citizenship')
  expect(page).to have_content('Verified')
end

Then(/^verification types should display as external source$/) do
  expect(page).to have_content('Social Security Number')
  expect(page).to have_content('Citizenship')
  expect(page).to have_content('External Source')
end

Given(/^consumer has outstanding verification and unverified enrollments$/) do
  family = user.person.primary_family
  rating_area = FactoryBot.create(:benefit_markets_locations_rating_area)
  enr = FactoryBot.create(:hbx_enrollment,
                           family: family,
                           household: family.active_household,
                           coverage_kind: "health",
                           effective_on: TimeKeeper.date_of_record - 2.months,
                           enrollment_kind: "open_enrollment",
                           kind: "individual",
                           submitted_at: TimeKeeper.date_of_record - 2.months,
                           rating_area_id: rating_area.id,
                           special_verification_period: TimeKeeper.date_of_record - 20.days)
  enr.hbx_enrollment_members << HbxEnrollmentMember.new(applicant_id: family.active_family_members[0].id,
                                                        eligibility_date: TimeKeeper.date_of_record - 2.months,
                                                        coverage_start_on: TimeKeeper.date_of_record - 2.months)
  enr.save!
  user.person.consumer_role.fail_residency!
end

Then(/^consumer should see Verification Due date label$/) do
  expect(page).to have_content('Due Date')
end

Then(/^consumer should see Documents We Accept link$/) do
  expect(page).to have_content('Documents We Accept')
end

Then(/^Individual should see cost saving documents for evidences$/) do
  expect(page).to have_css(IvlDocumentsPage.income_evidence)
  expect(page).to have_content('Coverage from a job')
  expect(page).to have_content('Coverage from another program')
  expect(page).to have_content('Coverage from MaineCare and Cub Care')
end

And(/^Individual clicks on Actions dropdown$/) do
  find_all('.v-type-actions')[-1].click
end

Then(/^Individual should see view history option/) do
  expect(page).to have_content('View History')
end

And(/^Individual clicks on view history$/) do
  find(:xpath, IvlDocumentsPage.view_history_option).click
end

Then(/^Individual should see request histories and verification types$/) do
  expect(page).to have_content('Verification History')
  expect(page).to have_content('Fdsh Hub Call')
  expect(page).to have_content('Requested Hub for verification')
end

And(/^Individual clicks on cancel button$/) do
  find('.btn', text: 'Cancel').click
end

Then(/^Individual should not see view history table$/) do
  expect(page).not_to have_content('Verification History')
end
