require 'rails_helper'

RSpec.describe "consumer_profiles/_employers_and_plans.html.erb" do
  let(:person) {FactoryGirl.create(:person)}
  let(:user) {FactoryGirl.create(:user, :person=>person)}
  let(:employee_role) { FactoryGirl.create(:employee_role) }
  let(:hbx_enrollment) { double(benefit_group_assignment: benefit_group_assignment, plan: plan) }
  let(:plan) { double(name: "my select plan") }

  context "when not waive" do
    let(:benefit_group_assignment) { double(coverage_waived?: false) }
    before :each do
      allow(employee_role).to receive(:effective_on).and_return(Date.new(2015,8,8))
      assign(:employee_role, employee_role)
      assign(:hbx_enrollments, [hbx_enrollment])
      assign(:person, person)
      assign(:change_plan, 'change')
      sign_in user
      render template: "consumer_profiles/_employers_and_plans.html.erb"
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
end
