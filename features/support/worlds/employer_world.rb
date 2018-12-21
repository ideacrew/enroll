module EmployerWorld

  def employer(*traits)
    attributes = traits.extract_options!
    @organization ||= FactoryGirl.create(
      :benefit_sponsors_organizations_general_organization,
      :with_aca_shop_cca_employer_profile,
      attributes.merge(site: site)
    )
  end

  def second_employer(*traits)
    attributes = traits.extract_options!
    @second_organization ||= FactoryGirl.create(
      :benefit_sponsors_organizations_general_organization,
      :with_aca_shop_cca_employer_profile,
      attributes.merge(site: site)
    )
  end

  def employer_profile
    @employer_profile = employer.employer_profile
  end
end

World(EmployerWorld)

And(/^there is an employer (.*?)$/) do |legal_name|
  employer legal_name: legal_name,
           dba: legal_name
  benefit_sponsorship(employer)
end

And(/^there is an another employer (.*?)$/) do |legal_name|
  second_employer legal_name: legal_name,
           dba: legal_name
  benefit_sponsorship(second_employer)
end

Given(/^at least one attestation document status is (.*?)$/) do |status|
  @employer_attestation_status = status
end

Given(/^employer (.*?) has hired this broker$/) do |employer|
  assign_broker_agency_account
  assign_person_to_broker_agency
  employer_profile.hire_broker_agency(broker_agency_profile)
  # Need to fix below later
  employer_profile.benefit_sponsorships.first.active_broker_agency_account.update(writing_agent_id:broker.person.broker_role.id)
end