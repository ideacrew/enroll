require 'rails_helper'

RSpec.describe "consumer_profiles/_employers_and_plans.html.erb" do
  let(:person) {FactoryGirl.create(:person)}
  let(:user) {FactoryGirl.create(:user, :person=>person)}
  let(:employee_role) { FactoryGirl.create(:employee_role) }
  let(:subscriber){ double("HbxEnrollmentMember", id: double("my id")) }
  let(:hbx_enrollment) { double(benefit_group_assignment: benefit_group_assignment,
    plan: plan,
    subscriber: subscriber,
    benefit_group_id: "my benefit group id",
    effective_on: "10/01/2015"
    ) }
  let(:carrier_profile){ instance_double("CarrierProfile", legal_name: "My legal name") }
  let(:plan) { double(name: "my select plan",
    carrier_profile: carrier_profile,
    plan_type: "hmo",
    metal_level: "bronze"
    ) }
  let(:employer_profile){ instance_double("EmployerProfile", legal_name: "My Silly Legal Name") }

  context "when not waive" do
    let(:benefit_group_assignment) { double(coverage_waived?: false) }
    before :each do
      allow(employee_role).to receive(:effective_on).and_return(Date.new(2015,8,8))
      assign(:employee_role, employee_role)
      assign(:hbx_enrollments, [hbx_enrollment])
      assign(:person, person)
      assign(:change_plan, 'change')
      assign(:employer_profile, employer_profile)
      sign_in user
      render template: "consumer_profiles/_employers_and_plans.html.erb"
    end

    it "should display info of employer/plan/employee" do
      expect(rendered).to match(/#{employer_profile.legal_name}/)
      expect(rendered).to match(/#{employee_role.hired_on.strftime("%m/%d/%Y")}/)
      expect(rendered).to match(/#{employee_role.effective_on.strftime("%m/%d/%Y")}/)
      expect(rendered).to match(/#{person.full_name}/)
      expect(rendered).to match(/#{person.hbx_id}/)
      expect(rendered).to match(/#{plan.carrier_profile.legal_name}/)
      expect(rendered).to match(/#{plan.name}/)
      expect(rendered).to match(/#{plan.plan_type}/i)
      expect(rendered).to match(/#{plan.metal_level.humanize}/)
      expect(rendered).to match(/#{hbx_enrollment.subscriber.id.to_s}/)
      expect(rendered).to match(/#{hbx_enrollment.benefit_group_id.to_s}/)
      expect(rendered).to match(/#{hbx_enrollment.effective_on}/)
    end

    it "should show the link of shop for plan" do
      expect(rendered).to match(/Shop for plans/)
      target = "a[href='/group_selection/new?change_plan=change&employee_role_id=#{employee_role.id}&person_id=#{person.id}']"
      expect(rendered).to match /#{target}/
    end

    it "should show the selected plan" do
      expect(rendered).to match /Your plan/
      expect(rendered).to match /#{plan.name}/
    end
  end

  context "when waive" do
    let(:benefit_group_assignment) { double(coverage_waived?: true) }
    before :each do
      allow(employee_role).to receive(:effective_on).and_return(Date.new(2015,8,8))
      assign(:employee_role, employee_role)
      assign(:hbx_enrollments, [hbx_enrollment])
      assign(:person, person)
      sign_in user
      render template: "consumer_profiles/_employers_and_plans.html.erb"
    end

    it "should show waive status" do
      expect(rendered).to match(/Coverage Waived/)
      expect(rendered).to match(/Waiver Reason/)
    end
  end

  context "when terminated" do
    let(:benefit_group_assignment) { double(coverage_waived?: false) }
    before :each do
      allow(employee_role).to receive(:effective_on).and_return(Date.new(2015,8,8))
      allow(hbx_enrollment).to receive(:coverage_terminated?).and_return(true)
      assign(:employee_role, employee_role)
      assign(:hbx_enrollments, [hbx_enrollment])
      assign(:person, person)
      sign_in user
      render template: "consumer_profiles/_employers_and_plans.html.erb"
    end

    it "should show terminate status" do
      expect(rendered).to match(/Coverage Terminated/)
      expect(rendered).to match(/Terminated on/)
    end
  end

  context "when employment_terminated" do
    let(:census_employee) {double(employment_terminated?: true)}
    let(:employee_role) {double(effective_on: Date.new(2015,8,8), census_employee: census_employee, id: 'employee_role')}
    let(:benefit_group_assignment) { double(coverage_waived?: false) }

    before :each do
      assign(:employee_role, employee_role)
      assign(:hbx_enrollments, [hbx_enrollment])
      assign(:person, person)
      assign(:employee_role, employee_role)
      sign_in user
      render template: "consumer_profiles/_employers_and_plans.html.erb"
    end

    it "should not show employer info" do
      expect(rendered).not_to match(/HIRED/)
      expect(rendered).not_to match(/ELIGIBLE FOR COVERAGE/)
    end
  end

  context "when not employment_terminated" do
    let(:census_employee) {double(employment_terminated?: false)}
    let(:employee_role) {double(effective_on: Date.new(2015,8,8), census_employee: census_employee, id: 'employee_role')}
    let(:benefit_group_assignment) { double(coverage_waived?: false) }

    before :each do
      assign(:employee_role, employee_role)
      assign(:hbx_enrollments, [hbx_enrollment])
      assign(:person, person)
      assign(:employee_role, employee_role)
      sign_in user
      render template: "consumer_profiles/_employers_and_plans.html.erb"
    end

    it "should show employer info" do
      expect(rendered).to match(/HIRED/)
      expect(rendered).to match(/ELIGIBLE FOR COVERAGE/)
    end
  end
end
