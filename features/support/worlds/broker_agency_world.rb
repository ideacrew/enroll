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
    @broker_role = FactoryBot.build(:broker_role)
  end

  def assign_broker_agency_account
    employer_profile.benefit_sponsorships << broker_agency_account
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
end

World(BrokerAgencyWorld)

Given(/^there is a Broker (.*?)$/) do |legal_name|
  new_broker legal_name: legal_name,
             dba: legal_name
end

And(/^the broker is assigned to a broker agency$/) do
  assign_person_to_broker_agency
end

And(/^Hbx Admin is on Broker Index of the Admin Dashboard$/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-brokers').click
end

Then(/^Hbx Admin is on Broker Index and clicks Broker Applicants$/) do
  find('.interaction-click-control-broker-applications').click
end

Then(/^Hbx Admin the clicks on current broker applicant show button$/) do
  find('.interaction-click-control-broker-show').click
end

