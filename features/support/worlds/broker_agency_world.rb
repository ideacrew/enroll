module BrokerAgencyWorld
  def broker_organization
    @broker_organization ||= FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, legal_name: 'First Legal Name', site: site)
  end

  def broker_agency_profile
    @broker_agency_profile = broker_organization.broker_agency_profile
  end

  def broker_agency_account
    @broker_agency_account ||= FactoryBot.build(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile)
  end

  def assign_person_to_broker_agency
    broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
    broker_agency_profile.approve! if broker_agency_profile.may_approve?
  end

  def broker_role
    @broker_role = FactoryBot.create(:broker_role)
  end

  def assign_broker_agency_account
    employer_profile.benefit_sponsorships.first.broker_agency_accounts << broker_agency_account
    employer_profile.organization.save!
  end

  def new_broker(*traits)
    attributes = traits.extract_options!
    @new_broker ||= FactoryBot.create(
      :benefit_sponsors_organizations_general_organization,
      :with_broker_agency_profile,
      attributes.merge(site: site)
    )
  end

  def create_broker_agency
    person = FactoryBot.create(:person, :with_work_email)
    @person2 = FactoryBot.create(:person, first_name: 'staff', last_name: 'member')
    FactoryBot.create(:user, person: @person2)
    @user ||= User.create(email: 'hbx_admin_role@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: 'hbx_admin_role@dc.gov', person: person)
    @user.update_attributes(last_portal_visited: "/benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/#{broker_agency_profile.id}")
    broker_agency_profile.update_attributes!(aasm_state: 'is_approved')
    broker_role = FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: @broker_agency_profile.id, person: person)
    broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
    @broker_agency_profile ||= broker_agency_profile
    broker_agency_staff_role = FactoryBot.build(:broker_agency_staff_role, broker_agency_profile_id: @broker_agency_profile.id)
    person.broker_agency_staff_roles << broker_agency_staff_role
  end

  def plan_design_organization
    @plan_design_organization ||= FactoryBot.create(:sponsored_benefits_plan_design_organization,
    owner_profile_id: broker_agency_profile.id,
    sponsor_profile_id: employer_profile.id)
  end
end

def has_active_broker_relationship
  plan_design_organization.update_attributes!(has_active_broker_relationship: true)
end

World(BrokerAgencyWorld)

Given(/^there is a Broker (.*?)$/) do |legal_name|
  new_broker legal_name: legal_name,
             dba: legal_name
end

Given(/^there is a Broker$/) do
  broker_organization
end

And(/^the broker is assigned to a broker agency$/) do
  assign_person_to_broker_agency
end

And(/^the broker is assigned to the employer$/) do
  plan_design_organization
  has_active_broker_relationship
  assign_broker_agency_account
end

And(/^Hbx Admin is on Broker Index of the Admin Dashboard$/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-brokers').click
end

Then(/^Hbx Admin is on Broker Index and clicks Broker Applicants$/) do
  find('.interaction-click-control-broker-applications').click
end

Then(/^Hbx Admin the clicks on current broker applicant show button$/) do
  find_all('.interaction-click-control-broker-show').first.click
end

Given(/^Broker Agency exists in Enroll$/) do
  create_broker_agency
end
