module GAWorld
  def general_agency(*traits)
    attributes = traits.extract_options!
    @general_agency ||= FactoryGirl.create :general_agency, *traits, attributes.merge(:general_agency_traits => :with_staff)
  end

  def user(*traits)
    attributes = traits.extract_options!
    @user ||= FactoryGirl.create :user, *traits, attributes
  end
end
World(GAWorld)

Given /^a general agency agent visits the DCHBX$/ do
  visit '/'
end

When /^they click the 'New General Agency' button$/ do
  click_link 'General Agency Registration'
end

Then /^they should see the new general agency form$/ do
  expect(page).to have_content('New General Agency')
  screenshot("general_agency_registration")
end

When /^they complete the new general agency form and hit the 'Submit' button$/ do
  fill_in 'organization[first_name]', with: Forgery(:name).first_name
  fill_in 'organization[last_name]', with: Forgery(:name).last_name
  fill_in 'jq_datepicker_ignore_organization[dob]', with: (Time.now - rand(20..50).years).strftime('%m/%d/%Y')
  find('.interaction-field-control-organization-email').click
  fill_in 'organization[email]', with: Forgery(:email).address
  fill_in 'organization[npn]', with: '2222222222'

  fill_in 'organization[legal_name]', with: (company_name = Forgery(:name).company_name)
  fill_in 'organization[dba]', with: company_name
  fill_in 'organization[fein]', with: '333333333'

  find(:xpath, "//p[contains(., 'Select Entity Kind')]").click
  find(:xpath, "//li[contains(., 'S Corporation')]").click

  find(:xpath, "//p[contains(., 'Select Practice Area')]").click
  find(:xpath, "//li[contains(., 'Both – Individual & Family AND Small Business Marketplaces')]").click

  find(:xpath, "//div[@class='language_multi_select']//p[@class='label']").click
  find(:xpath, "//li[contains(., 'English')]").click

  fill_in 'organization[office_locations_attributes][0][address_attributes][address_1]', with: Forgery(:address).street_address
  fill_in 'organization[office_locations_attributes][0][address_attributes][city]', with: 'Washington'

  find(:xpath, "//p[contains(., 'SELECT STATE')]").click
  find(:xpath, "//li[contains(., 'DC')]").click

  fill_in 'organization[office_locations_attributes][0][address_attributes][zip]', with: '20001'

  fill_in 'organization[office_locations_attributes][0][phone_attributes][area_code]', with: Forgery(:address).phone.match(/\((\d\d\d)\)/)[1]
  fill_in 'organization[office_locations_attributes][0][phone_attributes][number]', with: Forgery(:address).phone.match(/\)(.*)$/)[1]

  find('.interaction-click-control-create-general-agency').click
end

Then /^they should see a confirmation message$/ do
  expect(page).to have_content('Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed.')
end

Then /^a pending approval status$/ do
  expect(GeneralAgencyProfile.last.aasm_state).to eq('is_applicant')
end

Given /^an HBX admin exists$/ do
  user :with_family, :hbx_staff
end

And /^a general agency, pending approval, exists$/ do
  general_agency
  staff = general_agency.general_agency_profile.general_agency_staff_roles.order(id: :desc).first.general_agency_staff_roles.last
  staff.person.emails.last.update(kind: 'work')
end

When /^the HBX admin visits the general agency list$/ do
  login_as user, scope: :user
  visit exchanges_hbx_profiles_root_path
  click_link 'General Agencies'
end

Then /^they should see the pending general agency$/ do
  expect(page).to have_content(general_agency.legal_name)
  screenshot("general_agency_list")
end

When /^they click the link of general agency$/ do
  click_link general_agency.legal_name
end

Then /^they should see the home of general agency$/ do
  expect(page).to have_content("General Agency : #{general_agency.legal_name}")
  screenshot("general_agency_homepage")
end

When /^they visit the list of staff$/ do
  find('.interaction-click-control-staff').click
end

Then /^they should see the name of staff$/ do
  full_name = general_agency.general_agency_profile.general_agency_staff_roles.order(id: :desc).first.full_name
  expect(page).to have_content("General Agency Staff")
  expect(page).to have_content(general_agency.legal_name)
  expect(page).to have_content(full_name)
  screenshot("general_agency_staff_list")

  click_link full_name
end

When /^they approve the general agency$/ do
  click_link general_agency.general_agency_profile.general_agency_staff_roles.order(id: :desc).first.full_name
  screenshot("general_agency_staff_edit_page")
  click_button 'Approve'
end

Then /^they should see updated status$/ do
  expect(find('.alert')).to have_content('Staff approved successfully.')
  screenshot("general_agency_staff_approved")
end

Then /^the general agency should receive an email$/ do
  staff = general_agency.general_agency_profile.general_agency_staff_roles.order(id: :desc).first.general_agency_staff_roles.last
  open_email(staff.email_address)
end

Given /^a general agency, approved, awaiting account creation, exists$/ do
  general_agency
  staff = general_agency.general_agency_profile.general_agency_staff_roles.first.general_agency_staff_roles.last
  staff.person.emails.last.update(kind: 'work')
  staff.approve!
end

When /^the HBX admin visits the link received in the approval email$/ do
  staff = general_agency.general_agency_profile.general_agency_staff_roles.first.general_agency_staff_roles.last
  email_address = staff.email_address

  open_email(email_address)
  expect(current_email.to).to eq([email_address])

  invitation_link = links_in_email(current_email).first
  invitation_link.sub!(/http\:\/\/127\.0\.0\.1\:3000/, '')
  visit(invitation_link)
end

Then /^they should see an account creation form$/ do
  expect(page).to have_css('.interaction-click-control-create-account')
  screenshot("general_agency_staff_register_by_invitation")
end

When /^they complete the account creation form and hit the 'Submit' button$/ do
  email_address = general_agency.general_agency_profile.general_agency_staff_roles.first.emails.first.address
  fill_in "user[email]", with: email_address
  fill_in "user[password]", with: "aA1!aA1!aA1!"
  fill_in "user[password_confirmation]", with: "aA1!aA1!aA1!"
  click_button 'Create account'
end

Then /^they should see a welcome message$/ do
  expect(page).to have_content('Welcome to DC Health Link. Your account has been created.')
  screenshot("general_agency_homepage_for_staff")
end

Then /^they see the General Agency homepage$/ do
  expect(page).to have_content(general_agency.legal_name)
end
