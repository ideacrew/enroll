require "rails_helper"

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe Queries::PolicyAggregationPipeline, "Policy Queries", dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"
  include_context "setup employees with benefits"

  let(:subject) { Queries::PolicyAggregationPipeline.new }
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
  let(:renewal_state) { :enrollment_eligible }
  let(:open_enrollment_period)   { (effective_period.min.prev_month - 2.days)..(effective_period.min - 10.days) }
  let!(:effective_on) {effective_period.min}
  let!(:organization) {abc_organization}
  let!(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, start_on: current_benefit_package.start_on, benefit_group_id:nil, benefit_package: current_benefit_package, is_active:false)}
  let(:reference_product) {current_benefit_package.sponsored_benefits.first.reference_product}
  let!(:ce)  { census_employees[0]}
  let!(:person) {FactoryBot.create(:person, first_name: ce.first_name, last_name: ce.last_name, ssn:ce.ssn)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person:person)}
  let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: ce.id, benefit_sponsors_employer_profile_id: abc_profile.id)}
  let!(:initial_enrollment) { 
    hbx_enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                        household: family.active_household, 
                        aasm_state: "coverage_enrolled",
                        family: family,
                        rating_area_id: predecessor_application.recorded_rating_area_id,
                        sponsored_benefit_id: predecessor_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id: predecessor_application.benefit_packages.first.id,
                        benefit_sponsorship_id: predecessor_application.benefit_sponsorship.id,
                        employee_role_id: employee_role.id,
                        submitted_at:Date.new(2018,6,21)
                        ) 
    hbx_enrollment.benefit_sponsorship = benefit_sponsorship
    hbx_enrollment.save!
    hbx_enrollment
  }

  let!(:renewal_enrollment) { 
    hbx_enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                        household: family.active_household, 
                        family: family,
                        aasm_state: "coverage_selected",
                        rating_area_id: renewal_application.recorded_rating_area_id,
                        sponsored_benefit_id: renewal_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id: renewal_application.benefit_packages.first.id,
                        benefit_sponsorship_id: renewal_application.benefit_sponsorship.id,
                        employee_role_id: employee_role.id
                        ) 
    hbx_enrollment.benefit_sponsorship = benefit_sponsorship
    hbx_enrollment.save!
    hbx_enrollment
  }

  before do
    ce.update_attributes(:employee_role_id => employee_role.id )
  end

  context 'aggregation methods' do

    it 'base_pipeline' do
      expect(subject.pipeline).to eq (aggregation)
      expect(subject.base_pipeline).to eq (aggregation)
    end

    it 'add' do
      value = subject.add(step)
      expect(value.length).to eq aggregation.length + 1
    end

    it 'open_enrollment' do
      value = subject.open_enrollment
      expect(value.pipeline[4]).to eq (open_enrollment_query)
    end

    it 'filter_to_employers_hbx_ids' do
      orgs = BenefitSponsors::Organizations::Organization.where(:hbx_id => {"$in" => hbx_id_list}) 
      benefit_group_ids = orgs.map(&:active_benefit_sponsorship).flat_map(&:benefit_applications).flat_map(&:benefit_packages).map(&:_id)
      expect(subject.pipeline.count).to be 4
      subject.filter_to_employers_hbx_ids(hbx_id_list)
      expect(subject.pipeline.count).to be 5
      expect([subject.pipeline[4]]).to eq [{"$match"=> {"households.hbx_enrollments.sponsored_benefit_package_id"=>
                                                        {"$in"=>
                                                        [benefit_group_ids[0], benefit_group_ids[1]]}}}]
    end

    it 'exclude_employers_by_hbx_ids' do
      expect(subject.pipeline.count).to be 4
      value = subject.exclude_employers_by_hbx_ids(hbx_id_list)
      expect(subject.pipeline.count).to be 5
    end
  end
end



