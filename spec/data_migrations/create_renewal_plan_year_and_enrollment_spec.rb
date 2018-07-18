require "rails_helper"

require File.join(Rails.root, "app", "data_migrations", "create_renewal_plan_year_and_enrollment")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe CreateRenewalPlanYearAndEnrollment, dbclean: :after_each do

  let(:given_task_name) { "create_renewal_plan_year_and_passive_renewals" }
  subject { CreateRenewalPlanYearAndEnrollment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "create_renewal_plan_year_and_passive_renewals", dbclean: :after_each do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let(:market_inception) { TimeKeeper.date_of_record.year }
    let!(:current_effective_date) { Date.new(TimeKeeper.date_of_record.last_year.year, TimeKeeper.date_of_record.month, 1) }
    let(:aasm_state) { :active }
    let!(:save_catalog){ benefit_market.benefit_market_catalogs.map(&:save)}
    let(:business_policy) { instance_double("some_policy", success_results: "validated successfully")}
    let(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, benefit_package: current_benefit_package)}
    let(:product) { FactoryGirl.create(:benefit_markets_products_health_products_health_product)}
    let(:employee_role) { FactoryGirl.build(:employee_role, benefit_sponsors_employer_profile_id:abc_profile.id)}
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: nil, benefit_sponsors_employer_profile_id: abc_profile.id, benefit_sponsorship: benefit_sponsorship, :benefit_group_assignments => [benefit_group_assignment],employee_role_id:employee_role.id) }
    let(:person) {FactoryGirl.create(:person, ssn:census_employee.ssn)}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person:person)}
    let(:active_household) {family.active_household}
    let(:enrollment) { FactoryGirl.create(:hbx_enrollment, sponsored_benefit_package_id: current_benefit_package.id, effective_on:initial_application.effective_period.min, household:family.active_household,benefit_group_assignment_id: benefit_group_assignment.id, employee_role_id:employee_role.id, benefit_sponsorship_id:benefit_sponsorship.id)}

    before(:each) do
      person = family.primary_applicant.person
      person.employee_roles = [employee_role]
      person.employee_roles.map(&:save)
      active_household.hbx_enrollments =[enrollment]
      active_household.save!
    end

    context "when renewal_plan_year" do

      before(:each) do
        allow(ENV).to receive(:[]).with("fein").and_return(abc_organization.fein)
        allow(ENV).to receive(:[]).with("action").and_return("renewal_plan_year")
      end

      it "should create renewing draft plan year" do
        expect(abc_organization.employer_profile.benefit_applications.map(&:aasm_state)).to eq [:active]
        subject.migrate
        abc_organization.reload
        expect(abc_organization.employer_profile.benefit_applications.map(&:aasm_state)).to eq [:active,:draft]
        expect(family.active_household.hbx_enrollments.map(&:aasm_state)).to eq ['coverage_selected']
      end
    end

    context "trigger_renewal_py_for_employers" do

      before(:each) do
        allow(ENV).to receive(:[]).with("start_on").and_return(initial_application.effective_period.min)
        allow(ENV).to receive(:[]).with("action").and_return("trigger_renewal_py_for_employers")
      end

      it "should create renewing plan year" do
        expect(abc_organization.employer_profile.benefit_applications.map(&:aasm_state)).to eq [:active]
        subject.migrate
        abc_organization.reload
        expect(abc_organization.employer_profile.benefit_applications.map(&:aasm_state)).to eq [:active, :draft]
      end
    end
  end
end

