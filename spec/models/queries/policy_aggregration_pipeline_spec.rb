require "rails_helper"

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe Queries::PolicyAggregationPipeline, "Policy Queries", dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"
  include_context "setup renewal application"

  let(:instance) { Queries::PolicyAggregationPipeline.new }
  let(:aggregation) { [
                    { "$unwind" => "$households"},
                    { "$unwind" => "$households.hbx_enrollments"},
                    { "$match" => {"households.hbx_enrollments" => {"$ne" => nil}}},
                    { "$match" => {"households.hbx_enrollments.hbx_enrollment_members" => {"$ne" => nil}, "households.hbx_enrollments.external_enrollment" => {"$ne" => true}}}
                    ] }
   let(:step) { {'rspec' => "test"}}
   let(:open_enrollment_query) {{
                                "$match" => {
                                      "households.hbx_enrollments.enrollment_kind" => "open_enrollment" }
                                }}
  let(:hbx_id_list) {[abc_organization.hbx_id]}
  let(:first_name) {"Lynyrd"}
  let(:middle_name) {"Rattlesnake"}
  let(:last_name) {"Skynyrd"}
  let(:name_sfx) {"PhD"}
  let(:ssn) {"230987654"}
  let(:dob) {TimeKeeper.date_of_record - 31.years}
  let(:gender) {"male"}
  let(:hired_on) {TimeKeeper.date_of_record - 1.year}
  let(:is_business_owner) {false}
  let(:address) {Address.new(kind: "home", address_1: "221 R St, NW", city: "Washington", state: "DC", zip: "20001")}
  let(:autocomplete) {" lynyrd skynyrd"}
  let(:valid_params) {
    {
        employer_profile: abc_profile,
        first_name: first_name,
        middle_name: middle_name,
        last_name: last_name,
        name_sfx: name_sfx,
        ssn: ssn,
        dob: dob,
        gender: gender,
        hired_on: hired_on,
        is_business_owner: is_business_owner,
        address: address,
        benefit_sponsorship: abc_organization.active_benefit_sponsorship
    }
  }
  let(:initial_census_employee) {CensusEmployee.new(**valid_params)}
  let(:benefit_group_assignment) {FactoryBot.create(:benefit_sponsors_benefit_group_assignment, benefit_group: current_benefit_package, census_employee: initial_census_employee)}
  let(:valid_employee_role) {FactoryBot.build(:benefit_sponsors_employee_role, ssn: initial_census_employee.ssn, dob: initial_census_employee.dob, employer_profile: abc_profile)}
  let!(:user) {FactoryBot.create(:user, person: valid_employee_role.person)}
  let(:family){FactoryBot.create(:family,:with_primary_family_member)}
  let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let!(:hbx_enrollment){FactoryBot.create(:hbx_enrollment, hbx_enrollment_members:[hbx_enrollment_member], household:family.active_household)}

  let(:family_member){FactoryBot.create(:family_member, family: family,is_primary_applicant: false, is_active: true, person: valid_employee_role.person)}
  let!(:hbx_id_list) {[abc_organization.hbx_id]}
  let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
  let(:market_inception) { TimeKeeper.date_of_record.year }
  let!(:current_effective_date) { Date.new(TimeKeeper.date_of_record.last_year.year, TimeKeeper.date_of_record.month, 1) }
  let(:aasm_state) { :active }
  let!(:save_catalog){ benefit_market.benefit_market_catalogs.map(&:save)}
  let(:business_policy) { instance_double("some_policy", success_results: "validated successfully")}
  let!(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, start_on: current_benefit_package.start_on, benefit_group_id:nil, benefit_package: current_benefit_package, is_active:false)}
  let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product)}
  let(:employee_role) { FactoryBot.build(:employee_role, benefit_sponsors_employer_profile_id:abc_profile.id)}
  let(:census_employee) { FactoryBot.create(:census_employee, dob: TimeKeeper.date_of_record - 21.year, employer_profile_id: nil, benefit_sponsors_employer_profile_id: abc_profile.id, benefit_sponsorship: benefit_sponsorship, :benefit_group_assignments => [benefit_group_assignment],employee_role_id:employee_role.id) }
  let(:person) {FactoryBot.create(:person, first_name: census_employee.first_name, last_name: census_employee.last_name, dob: TimeKeeper.date_of_record - 21.year, ssn:census_employee.ssn)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person:person)}
  let(:active_household) {family.active_household}
  let(:sponsored_benefit) {current_benefit_package.sponsored_benefits.first}
  let(:reference_product) {current_benefit_package.sponsored_benefits.first.reference_product}
  let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true, coverage_start_on: current_benefit_package.start_on, eligibility_date: current_benefit_package.start_on, applicant_id: family.family_members.first.id) }
  let(:enrollment) { FactoryBot.create(:hbx_enrollment, hbx_enrollment_members:[hbx_enrollment_member],product: reference_product, sponsored_benefit_package_id: current_benefit_package.id, effective_on:initial_application.effective_period.min, household:family.active_household,benefit_group_assignment_id: benefit_group_assignment.id, employee_role_id:employee_role.id, benefit_sponsorship_id:benefit_sponsorship.id)}
  let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
  let!(:update_reference_product) {reference_product.update_attributes(issuer_profile_id:issuer_profile.id)}

  before(:each) do
    person = family.primary_applicant.person
    person.employee_roles = [employee_role]
    person.employee_roles.map(&:save)
    active_household.hbx_enrollments =[enrollment]
    active_household.save!
  end
  context 'aggregation methods' do

    before do
      initial_census_employee.benefit_group_assignments = [benefit_group_assignment]
      initial_census_employee.save
    end

    it 'base_pipeline' do
      expect(instance.pipeline).to eq (aggregation)
      expect(instance.base_pipeline).to eq (aggregation)
    end

    it 'add' do
      value = instance.add(step)
      expect(value.length).to eq aggregation.length + 1
    end

    it 'open_enrollment' do
      value = instance.open_enrollment
      expect(value.pipeline[4]).to eq (open_enrollment_query)
    end

    it 'filter_to_employers_hbx_ids' do
      orgs = BenefitSponsors::Organizations::Organization.where(:hbx_id => {"$in" => hbx_id_list}) 
      benefit_group_ids = orgs.map(&:active_benefit_sponsorship).flat_map(&:benefit_applications).flat_map(&:benefit_packages).map(&:_id)
      expect(instance.pipeline.count).to be 4
      instance.filter_to_employers_hbx_ids(hbx_id_list)
      expect(instance.pipeline.count).to be 5
      expect([instance.pipeline[4]]).to eq [{"$match"=> {"households.hbx_enrollments.sponsored_benefit_package_id"=>
                                                        {"$in"=>
                                                        [benefit_group_ids[0]]}}}]
    end

    it 'exclude_employers_by_hbx_ids' do
      expect(instance.pipeline.count).to be 4
      value = instance.exclude_employers_by_hbx_ids(hbx_id_list)
      expect(instance.pipeline.count).to be 5
    end
  end
end



