require 'rails_helper'

RSpec.describe PlanCostDecoratorCongress, dbclean: :after_each do
  let!(:plan_year)          { double("PlanYear", start_on: Date.today.beginning_of_year) }
  let!(:benefit_group)      { double("BenefitGroupCongress", plan_year: plan_year) }
  let(:hbx_enrollment)      { double("HbxEnrollment", class: HbxEnrollment, hbx_enrollment_members: hbx_enrollment_members) }
  let!(:hem_employee)       { double("HbxEnrollmentMember_Employee", class: HbxEnrollmentMember, _id: "a", age_on_effective_date: 19, is_subscriber?: true , primary_relationship: "self") }
  let!(:hem_spouse)         { double("HbxEnrollmentMember_Spouse",   class: HbxEnrollmentMember, _id: "b", age_on_effective_date: 20, is_subscriber?: false, primary_relationship: "spouse") }
  let!(:hem_child_1)        { double("HbxEnrollmentMember_Child_1",  class: HbxEnrollmentMember, _id: "c", age_on_effective_date: 18, is_subscriber?: false, primary_relationship: "child") }
  let!(:hem_child_2)        { double("HbxEnrollmentMember_Child_2",  class: HbxEnrollmentMember, _id: "d", age_on_effective_date: 13, is_subscriber?: false, primary_relationship: "child") }
  let!(:hem_child_3)        { double("HbxEnrollmentMember_Child_3",  class: HbxEnrollmentMember, _id: "e", age_on_effective_date: 10, is_subscriber?: false, primary_relationship: "child") }
  # let!(:ce_employee)        { double("CensusEmployee_Employee", class: CensusEmployee , age_on: 19, employee_relationship: "employee", census_dependents: []) }
  # let!(:cd_spouse)          { double("CensusDependent_Spouse",  class: CensusDependent, age_on: 20, employee_relationship: "spouse") }
  # let!(:cd_child_1)         { double("CensusDependent_Child_1", class: CensusDependent, age_on: 18, employee_relationship: "child_under_26") }
  # let!(:cd_child_2)         { double("CensusDependent_Child_2", class: CensusDependent, age_on: 13, employee_relationship: "child_under_26") }
  # let!(:cd_child_3)         { double("CensusDependent_Child_3", class: CensusDependent, age_on: 10, employee_relationship: "child_under_26") }
  let!(:plan_year)          { double("PlanYear", start_on: Date.today.beginning_of_year) }
  let!(:benefit_group)      { double("BenefitGroupCongress", plan_year: plan_year, contribution_pct_as_int: 75, employee_max_amt_in_cents: 100, first_dependent_max_amt_in_cents: 200, over_one_dependents_max_amt_in_cents: 300) }
  let!(:chosen_plan)        { double("ChosenPlan", id: "chosen_plan_id") }

  before do
    allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * premium_constant}
  end

  context "rating an hbx enrollment" do
    let(:plan_cost_decorator) { PlanCostDecoratorCongress.new(chosen_plan, hbx_enrollment, benefit_group) }

    context "with no dependents" do
      let(:hbx_enrollment_members) { [hem_employee] }

      it "should be possible to construct a new plan cost decorator" do
        expect(plan_cost_decorator.class).to be PlanCostDecoratorCongress
      end

      context "below contribution cap" do
        let(:premium_constant) { 1.0 }
        before do
          allow(benefit_group).to receive(:employee_max_amt_in_cents).and_return(hem_employee.age_on_effective_date * 10)
          # allow(benefit_group).to receive(:first_dependent_max_amt_in_cents).and_return(hem_employee.age_on_effective_date * 10)
          # allow(benefit_group).to receive(:over_one_dependents_max_amt_in_cents).and_return(hem_employee.age_on_effective_date * 10)
        end

        it "should have an employer contribution for employee" do
          expect(plan_cost_decorator.employer_contribution_for(hem_employee)).to eq hem_employee.age_on_effective_date * benefit_group.contribution_pct_as_int / 100.0
        end
      end

      context "above contribution cap" do
        let(:premium_constant) { 100.0 }
        before do
          allow(benefit_group).to receive(:employee_max_amt_in_cents).and_return(hem_employee.age_on_effective_date )
          # allow(benefit_group).to receive(:first_dependent_max_amt_in_cents).and_return(hem_employee.age_on_effective_date * 10)
          # allow(benefit_group).to receive(:over_one_dependents_max_amt_in_cents).and_return(hem_employee.age_on_effective_date * 10)
        end

        it "should have an employer contribution for employee" do
          expect(plan_cost_decorator.employer_contribution_for(hem_employee)).to eq benefit_group.employee_max_amt_in_cents
        end
      end
    end

    context "with spouse, no children" do
      let(:hbx_enrollment_members) { [hem_employee, hem_spouse] }

      it "should be possible to construct a new plan cost decorator" do
        expect(plan_cost_decorator.class).to be PlanCostDecoratorCongress
      end

      context "below contribution cap" do
        let(:premium_constant) { 1.0 }
        before do
          allow(benefit_group).to receive(:employee_max_amt_in_cents).and_return(hem_employee.age_on_effective_date * 10)
          allow(benefit_group).to receive(:first_dependent_max_amt_in_cents).and_return(hem_spouse.age_on_effective_date * 20)
          # allow(benefit_group).to receive(:over_one_dependents_max_amt_in_cents).and_return(hem_employee.age_on_effective_date * 10)
        end

        it "should have an employer contribution for employee" do
          expect(plan_cost_decorator.employer_contribution_for(hem_employee)).to eq hem_employee.age_on_effective_date * benefit_group.contribution_pct_as_int / 100.0
        end
      end

      context "above contribution cap" do
        let(:premium_constant) { 100.0 }
        before do
          allow(benefit_group).to receive(:employee_max_amt_in_cents).and_return(hem_employee.age_on_effective_date )
          allow(benefit_group).to receive(:first_dependent_max_amt_in_cents).and_return(hem_spouse.age_on_effective_date * 2)
          # allow(benefit_group).to receive(:over_one_dependents_max_amt_in_cents).and_return(hem_employee.age_on_effective_date * 10)
        end

        it "should have a total employer contribution" do
          expect(plan_cost_decorator.total_employer_contribution).to eq benefit_group.first_dependent_max_amt_in_cents
        end
      end

    end

    # context "with child, no spouse" do
    #   before do
    #     allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([hem_employee, hem_child_1])
    #   end
    #
    # end
    #
    # context "with spouse and child" do
    #   before do
    #     allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([hem_employee, hem_spouse, hem_child_1])
    #   end
    #
    # end
    #
    # context "with two children, no spouse" do
    #   before do
    #     allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([hem_employee, hem_child_1, hem_child_2])
    #   end
    #
    # end
    #
    # context "with spouse and two children" do
    #   before do
    #     allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([hem_employee, hem_spouse, hem_child_1, hem_child_2])
    #   end
    #
    # end
    #
    # context "with three children" do
    #   before do
    #     allow(hbx_enrollment).to receive(:hbx_enrollment_members).and_return([hem_employee, hem_child_1, hem_child_2, hem_child_3])
    #   end
    #
    # end
  end
end
