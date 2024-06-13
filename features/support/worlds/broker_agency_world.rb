module BrokerAgencyWorld
  def create_prospect_employer(broker_agency_name)
    broker_agency_profile = broker_agency_profile(broker_agency_name)
    organization_params = {
      "legal_name" => "emp1",
      "dba" => "101010",
      "entity_kind" => "c_corporation",
      "office_locations_attributes" => {
        "0" => {
          "address_attributes" => {
            "kind" => "primary",
            "address_1" => "1818 exp st",
            "address_2" => "",
            "city" => EnrollRegistry[:enroll_app].setting(:contact_center_city).item,
            "state" => EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
            "zip" => EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item
          },
          "phone_attributes" => {
            "kind" => "work", "area_code" => "202", "number" => "555-2121", "extension" => ""
          }
        }
      }
    }
    SponsoredBenefits::Organizations::BrokerAgencyProfile.init_prospect_organization(
      broker_agency_profile,
      organization_params.merge(owner_profile_id: broker_agency_profile.id)
    )
  end

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

  def all_broker_agencies
    Person.all.select { |p| p.broker_role.present? }.map { |person| person.broker_role.broker_agency_profile }
  end

  def broker_agency_profile(legal_name = nil)
    broker_agency_organization(legal_name).broker_agency_profile if broker_agency_organization(legal_name).present?
  end

  def assign_broker_to_broker_agency(broker_name, legal_name)
    @brokers ||= {}
    return @brokers[broker_name] if @brokers[broker_name]

    broker_agency_profile = broker_agency_profile(legal_name)
    person = FactoryBot.create(:person, :with_work_email, first_name: broker_name.split(/\s/)[0], last_name: broker_name.split(/\s/)[1])
    @brokers[broker_name] = create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person)
    person.broker_agency_staff_roles << build(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id)
    @broker_agency_staff = create(:user, person: person, email: people[broker_name][:email], password: people[broker_name][:password], password_confirmation: people[broker_name][:password])
    @broker_agency_staff.update_attributes(last_portal_visited: "/benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/#{broker_agency_profile.id}")
  end

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

  def broker_agency_profile_with_organization(*traits)
    attributes = traits.extract_options!
    @broker_agency_profile_with_organization ||= FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, *traits, attributes)
  end
end

World(BrokerAgencyWorld)

Given(/^an individual market broker exists$/) do
  @broker_agency_profile = broker_agency_profile_with_organization market_kind: :individual
  broker :with_family, :broker_with_person, organization: @broker_agency_profile.organization
end

And(/^a consumer role family exists with broker$/) do
  @person = FactoryBot.create(:person, :with_family, :with_consumer_role)
  @person.consumer_role.move_identity_documents_to_verified
  @person.primary_family.broker_agency_accounts.create!(
    start_on: TimeKeeper.date_of_record,
    benefit_sponsors_broker_agency_profile_id: @broker_agency_profile.id,
    writing_agent_id: @broker_agency_profile.primary_broker_role.id,
    is_active: true
  )
  #@person.reload
  puts "@person #{@person.inspect}"
  puts "@person.primary_family.inspect #{@person.primary_family.inspect}"
  # sleep 10
  # @person.broker_role
end

And(/^broker lands on broker agency home page$/) do
  visit benefit_sponsors.profiles_broker_agencies_broker_agency_profile_path(id: @broker_agency_profile)
end

And(/^broker clicks on the name of the person in family index$/) do
  person_name = @person&.first_name || 'John'
  find('a', :text => person_name, :wait => 5).click
end

Given(/^there is a Broker Agency exists for (.*?)$/) do |broker_agency_name|
  broker_agency_organization broker_agency_name, legal_name: broker_agency_name, dba: broker_agency_name

  broker_agency_profile(broker_agency_name).update_attributes!(aasm_state: 'is_approved')
end


# Following step will move broker role to the given state
# ex: the broker Max Planck application is in denied
#     the broker Max Planck application is in applicant
#     the broker Max Planck application is in decertified
And(/^the broker (.*?) application is in (.*?) state$/) do |broker_name, broker_role_state|
  @brokers[broker_name].update_attributes(aasm_state: broker_role_state)
  # makes the current broker as the primary broker of the organization
  broker_agency_profile.update_attributes!(primary_broker_role_id: @brokers[broker_name].id)
  # Don't need a staff role for this scenario
  @brokers[broker_name].person.broker_agency_staff_roles[0].destroy
end

And(/^the broker (.*?) is primary broker for (.*?)$/) do |broker_name, broker_agency_name|
  assign_broker_to_broker_agency(broker_name, broker_agency_name)
end

And(/^employer (.*?) is listed under the account for broker (.*?)$/) do |employer_name, broker_agency_name|
  employer = BenefitSponsors::Organizations::Organization.all.detect { |org| org.legal_name == employer_name }
  sponsorship = employer.employer_profile.benefit_sponsorships.last
  broker_agency = BenefitSponsors::Organizations::Organization.all.detect { |org| org.legal_name == broker_agency_name }
  broker_agency_prof = broker_agency.broker_agency_profile
  broker_agency_under_sponsorships = sponsorship.broker_agency_accounts.detect { |broker_agency_account| broker_agency_account.broker_agency_profile == broker_agency_prof }
  raise("No broker agency under sponsorship") if broker_agency_under_sponsorships.blank?
  dt_query = nil
  query = BenefitSponsors::Queries::BrokerFamiliesQuery.new(dt_query, broker_agency_prof.id, broker_agency_prof.market_kind)
  census_employee_names = employer.employer_profile.census_employees.map(&:full_name)
  query_family_primary_person_names = query.filtered_scope.map { |query_family| query_family&.primary_person&.full_name }
  census_employee_names.each { |ce_name| expect(query_family_primary_person_names).to include(ce_name) }
end

And(/^employer (.*?) hired broker (.*?) from (.*?)$/) do |employer_name, broker_name, broker_agency_name|
  plan_design_organization(employer_name, broker_agency_name)
  assign_broker_agency_account(broker_name, broker_agency_name)
end

Given(/^employer (.*?) is a prospect client$/) do |legal_name|
  employer = SponsoredBenefits::Organizations::PlanDesignOrganization.where(legal_name: legal_name).first
  employer.update_attributes!(sponsor_profile_id: nil, has_active_broker_relationship: false)
end

Given(/^employer (.*?) has OSSE eligibilities$/) do |legal_name|
  org = BenefitSponsors::Organizations::Organization.find_by(legal_name: legal_name)
  aba = org.active_benefit_sponsorship.active_benefit_application
  rba = org.active_benefit_sponsorship.renewal_benefit_application

  eligibility1 = FactoryBot.build(:benefit_sponsors_shop_osse_eligibility,
                                  :with_admin_attested_evidence,
                                  evidence_state: :approved,
                                  is_eligible: true)

  org.active_benefit_sponsorship.eligibilities = []
  org.active_benefit_sponsorship.eligibilities << eligibility1
  org.save!
  org.active_benefit_sponsorship.reload
end

Given(/^employer (.*?) has OSSE eligibilities created during effective period$/) do |legal_name|
  org = BenefitSponsors::Organizations::Organization.find_by(legal_name: legal_name)
  aba = org.active_benefit_sponsorship.active_benefit_application
  rba = org.active_benefit_sponsorship.renewal_benefit_application

  eligibility1 = FactoryBot.build(:benefit_sponsors_shop_osse_eligibility,
                                  :with_admin_attested_evidence,
                                  evidence_state: :approved,
                                  is_eligible: true,
                                  effective_on: (aba.effective_period.min + 2.days).beginning_of_year)
  eligibility2 = FactoryBot.build(:benefit_sponsors_shop_osse_eligibility,
                                  :with_admin_attested_evidence,
                                  evidence_state: :approved,
                                  is_eligible: true,
                                  effective_on: (rba.effective_period.min + 2.days).beginning_of_year)
  org.active_benefit_sponsorship.eligibilities = []
  org.active_benefit_sponsorship.eligibilities << eligibility1
  org.active_benefit_sponsorship.eligibilities << eligibility2
  org.active_benefit_sponsorship.save!
end

Given(/^employer (.*?) is OSSE eligible$/) do |legal_name|
  org = BenefitSponsors::Organizations::Organization.find_by(legal_name: legal_name)
  bs = org.active_benefit_sponsorship
  eligibility = FactoryBot.build(:benefit_sponsors_shop_osse_eligibility,
                                 :with_admin_attested_evidence,
                                 evidence_state: :approved,
                                 is_eligible: true)

  bs.eligibilities = []
  bs.eligibilities << eligibility
  bs.save!
end

And(/^Hbx Admin is on Broker Index of the Admin Dashboard$/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-brokers').click
end

Then(/^Hbx Admin is on Broker Index and clicks Broker Applicants$/) do
  find('.interaction-click-control-broker-applications').click
end

Then(/^Hbx Admin clicks on (.*?) tab$/) do |tab_name|
  find("label", text: tab_name.titleize).click
end

Then(/^Hbx Admin is on Broker Index and clicks Broker Agencies$/) do
  find('.interaction-click-control-broker-agencies').click
end

Then(/^Hbx Admin clicks on the current broker applicant show button$/) do
  wait_for_ajax
  find_all('.interaction-click-control-broker-show').first.click
  expect(page).to have_content("HBX")
end

And(/^person record exists for (.*?)$/) do |name|
  create_person_record(name)
end
