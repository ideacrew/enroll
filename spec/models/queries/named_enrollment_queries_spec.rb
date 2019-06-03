require "rails_helper"

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"


describe Queries::NamedEnrollmentQueries, "Policy Queries", dbclean: :after_each do
  # TODO Queries::NamedPolicyQueries.shop_monthly_enrollments(feins, effective_on) updated to new model in
  # app/models/queries/named_enrollment_queries.rb
  # context "Shop Monthly Queries" do

  describe "given an employer who has completed their first open enrollment" do
    describe "with employees who have made the following plan selections: 
#        - employee A has purchased:
#          - One health enrollment (Enrollment 1)
#        - employee B has purchased:
#          - One health enrollment (Enrollment 2)
#          - Then a health waiver (Enrollment 3)
#        - employee C has purchased:
#          - One health enrollment (Enrollment 4)
#          - One dental enrollment (Enrollment 5)
#          - Then a health waiver (Enrollment 6)
#          - Then another health enrollment (Enrollment 7) " do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup renewal application"
    include_context "setup employees"


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
    # let(:enrollment) { FactoryBot.create(:hbx_enrollment, hbx_enrollment_members:[hbx_enrollment_member],product: reference_product, sponsored_benefit_package_id: current_benefit_package.id, effective_on:predecessor_application.effective_period.min, household:family.active_household,benefit_group_assignment_id: benefit_group_assignment.id, employee_role_id:employee_role.id, benefit_sponsorship_id:benefit_sponsorship.id)}
    let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
    let!(:update_reference_product) {reference_product.update_attributes(issuer_profile_id:issuer_profile.id)}
    let!(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, start_on: current_benefit_package.start_on, benefit_group_id:nil, benefit_package: current_benefit_package, is_active:false)}
    let(:reference_product) {current_benefit_package.sponsored_benefits.first.reference_product}
    let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true, coverage_start_on: current_benefit_package.start_on, eligibility_date: current_benefit_package.start_on, applicant_id: family.family_members.first.id) }
    let(:enrollment) { FactoryBot.create(:hbx_enrollment, hbx_enrollment_members:[hbx_enrollment_member],product: reference_product,sponsored_benefit_id:sponsored_benefit.id, sponsored_benefit_package_id: current_benefit_package.id, effective_on:predecessor_application.effective_period.min, household:family.active_household,benefit_group_assignment_id: benefit_group_assignment.id, employee_role_id:employee_role.id, benefit_sponsorship_id:benefit_sponsorship.id, submitted_at:Date.new(2018,6,21))}
    let!(:person) {FactoryBot.create(:person, first_name: ce.first_name, last_name: ce.last_name, ssn:ce.ssn)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person:person)}
    let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: ce.id, benefit_sponsors_employer_profile_id: abc_profile.id)}
    let!(:ce)  { census_employees[0]}
    let(:subject) {::Queries::NamedEnrollmentQueries.new}

      before do
        ce.update_attributes(:employee_role_id => employee_role.id )

      end
      before(:each) do
        person = family.primary_applicant.person
        person.employee_roles = [employee_role]
        person.employee_roles.map(&:save)
        active_household.hbx_enrollments =[enrollment]
        active_household.save!
      end


      it '.shop_initial_enrollments' do 
        ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.by_profile(abc_organization.employer_profile).first.benefit_applications.first.update_attributes(aasm_state:"binder_paid",effective_period:predecessor_application.effective_period)
        query =  ::Queries::NamedEnrollmentQueries.shop_initial_enrollments(abc_organization,predecessor_application.effective_period.min)
        expect(query.map{|er|er}).to include (enrollment.hbx_id)
      end
      
      it '.find_simulated_renewal_enrollments' do 
        ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.by_profile(abc_organization.employer_profile).first.benefit_applications.first.update_attributes(aasm_state:"binder_paid",effective_period:predecessor_application.effective_period)
        query =  ::Queries::NamedEnrollmentQueries.find_simulated_renewal_enrollments(current_benefit_package.sponsored_benefits, predecessor_application.effective_period.min, as_of_time = ::TimeKeeper.date_of_record)
        expect(query.map{|er|er}).to include (enrollment.hbx_id)
      end
    end
  end
end


