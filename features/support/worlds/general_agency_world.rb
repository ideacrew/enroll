module GeneralAgencyWorld
  def general_agency_organization
    @general_agency_organization ||= FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, legal_name: 'First Legal Name', site: site)
  end

  def general_agency_profile
    @general_agency_profile = general_agency_organization.general_agency_profile
  end
end

def assign_roles_to_general_agency
  general_agency_profile.general_agency_staff_roles << general_agency_staff_role
  general_agency_profile.save!
end

def general_agency_staff_role
  @general_agency_staff_role = FactoryBot.create(:general_agency_staff_role,
    benefit_sponsors_general_agency_profile_id: general_agency_profile.id)
end

World(GeneralAgencyWorld)

And /^a general agency, pending approval, exists$/ do
  assign_roles_to_general_agency
  staff = general_agency_organization.general_agency_profile.general_agency_staff_roles.last
  staff.person.emails.last.update(kind: 'work')
end

Then /^they should see the name of staff$/ do
  full_name = general_agency_organization.general_agency_profile.general_agency_staff_roles.last.person.full_name
  expect(page).to have_content("General Agency Staff")
  expect(page).to have_content(general_agency_organization.legal_name)
  expect(page).to have_content(full_name)
  screenshot("general_agency_staff_list")

  click_link full_name
end

Then /^the general agency should receive an email$/ do
  staff = general_agency_organization.general_agency_profile.general_agency_staff_roles.last
  open_email(staff.email_address)
end

Given /^a general agency, approved, awaiting account creation, exists$/ do
  assign_roles_to_general_agency
  staff = general_agency_organization.general_agency_profile.general_agency_staff_roles.last
  staff.person.emails.last.update(kind: 'work')
  staff.approve!
end

When /^the HBX admin visits the link received in the approval email$/ do
  staff = general_agency_organization.general_agency_profile.general_agency_staff_roles.last
  email_address = staff.email_address

  open_email(email_address)
  expect(current_email.to).to eq([email_address])

  invitation_link = links_in_email(current_email).first
  invitation_link.sub!(/http\:\/\/127\.0\.0\.1\:3000/, '')
  visit(invitation_link)
end
