module BrokerAgencyWorld

  # def broker_organization
  #   @broker_organization ||= FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, legal_name: 'First Legal Name', site: site)
  # end

  # def broker_agency_profile
  #   @broker_agency_profile = broker_organization.broker_agency_profile
  # end

  # def broker_agency_account
  #   @broker_agency_account ||= FactoryBot.build(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile)
  # end

  # def assign_person_to_broker_agency(broker_agency_name)
  #   broker_agency_profile = broker_agency_profile(broker_agency_name)
  #   broker_agency_profile.active_broker_roles.first

  #   broker_agency_profile.broker_agency_staff_role
  #   broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
  #   broker_agency_profile.approve! if broker_agency_profile.may_approve?
  # end

  # def broker_role
  #   @broker_role = FactoryBot.create(:broker_role)
  # end

  def assign_broker_agency_account(broker_name, broker_agency_name)
    broker_agency_profile = broker_agency_profile(broker_agency_name)
    sponsorship = employer_profile.benefit_sponsorships.first
    sponsorship.broker_agency_accounts << build(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, writing_agent_id: @brokers[broker_name].id)
    sponsorship.organization.save!
  end

  def broker_agency_organization(legal_name = nil, *traits)
    attributes = traits.extract_options!
    traits.push(:with_broker_agency_profile)
    @broker_agency_profiles ||= {}

    if legal_name.blank?
      if @broker_agency_profiles.empty?
        @broker_agency_profiles[:default] ||= FactoryBot.create(:benefit_sponsors_organizations_general_organization,
                                                                *traits,
                                                                attributes.merge(site: site))
      else
        @broker_agency_profiles.values.first
      end
    else
      @broker_agency_profiles[legal_name] ||= FactoryBot.create(:benefit_sponsors_organizations_general_organization,
                                                                *traits,
                                                                attributes.merge(site: site))
    end
  end

  def broker_agency_profile(legal_name = nil)
    broker_agency_organization(legal_name).broker_agency_profile if broker_agency_organization(legal_name).present?
  end

  # def new_broker(*traits)
  #   attributes = traits.extract_options!
  #   @new_broker ||= FactoryBot.create(
  #     :benefit_sponsors_organizations_general_organization,
  #     :with_broker_agency_profile,
  #     attributes.merge(site: site)
  #   )
  # end

  def assign_broker_to_broker_agency(broker_name, legal_name)
    @brokers ||= {}
    return @brokers[broker_name] if @brokers[:broker_name]

    broker_agency_profile = broker_agency_profile(legal_name)
    person = FactoryBot.create(:person, :with_work_email, first_name: broker_name.split(/\s/)[0], last_name: broker_name.split(/\s/)[1])
    @brokers[broker_name] = create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person)
    person.broker_agency_staff_roles << build(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id)
    @broker_agency_staff = create(:user, person: person, email: people[broker_name][:email], password: people[broker_name][:password], password_confirmation: people[broker_name][:password])
    @broker_agency_staff.update_attributes(last_portal_visited: "/benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/#{broker_agency_profile.id}")
  end

  # def create_broker_agency
  #   person = FactoryBot.create(:person, :with_work_email)
  #   @person2 = FactoryBot.create(:person, first_name: 'staff', last_name: 'member')
  #   FactoryBot.create(:user, person: @person2)
  #   @user ||= User.create(email: 'hbx_admin_role@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: 'hbx_admin_role@dc.gov', person: person)
  #   @user.update_attributes(last_portal_visited: "/benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/#{broker_agency_profile.id}")
  #   broker_agency_profile.update_attributes!(aasm_state: 'is_approved')
  #   broker_role = FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: @broker_agency_profile.id, person: person)
  #   broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
  #   @broker_agency_profile ||= broker_agency_profile
  #   broker_agency_staff_role = FactoryBot.build(:broker_agency_staff_role, broker_agency_profile_id: @broker_agency_profile.id)
  #   person.broker_agency_staff_roles << broker_agency_staff_role
  # end

  def plan_design_organization(employer_name, broker_agency_name = nil)
    sponsor = employer_profile(employer_name)
    @plan_design_organization ||= FactoryBot.create(:sponsored_benefits_plan_design_organization,
                                                    owner_profile_id: broker_agency_profile(broker_agency_name).id,
                                                    sponsor_profile_id: sponsor.id,
                                                    legal_name: sponsor.legal_name,
                                                    dba: sponsor.dba,
                                                    fein: sponsor.fein,
                                                    has_active_broker_relationship: true)
  end

  def create_person_record(name)
    person = people[name]
    person_rec = FactoryBot.create(:person, first_name: person[:first_name], last_name: person[:last_name], dob: Date.strptime(person[:dob], "%m/%d/%Y"))
    FactoryBot.create(:user, person: person_rec, email: person[:email])
  end
end

World(BrokerAgencyWorld)

Given(/^there is a Broker Agency exists for (.*?)$/) do |broker_agency_name|
  broker_agency_organization broker_agency_name, legal_name: broker_agency_name, dba: broker_agency_name

  broker_agency_profile(broker_agency_name).update_attributes!(aasm_state: 'is_approved')
end

# Given(/^there is a Broker$/) do
#   broker_organization
# end

And(/^the broker (.*?) is primary broker for (.*?)$/) do |broker_name, broker_agency_name|
  assign_broker_to_broker_agency(broker_name, broker_agency_name)
end

And(/^employer (.*?) hired broker (.*?) from (.*?)$/) do |employer_name, broker_name, broker_agency_name|
  plan_design_organization(employer_name, broker_agency_name)
  assign_broker_agency_account(broker_name, broker_agency_name)
end

And(/^Hbx Admin is on Broker Index of the Admin Dashboard$/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-brokers').click
end

Then(/^Hbx Admin is on Broker Index and clicks Broker Applicants$/) do
  find('.interaction-click-control-broker-applications').click
end

Then(/^Hbx Admin is on Broker Index and clicks Broker Agencies$/) do
  find('.interaction-click-control-broker-agencies').click
end

Then(/^Hbx Admin the clicks on current broker applicant show button$/) do
  find_all('.interaction-click-control-broker-show').first.click
end

And(/^person record exists for (.*?)$/) do |name|
  create_person_record(name)
end