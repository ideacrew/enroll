require 'rails_helper'

shared_examples "an assignment that starts when the group starts", :shared => true do
  it "should be assigned starting on the benefit group start" do
    expect(benefit_group_assignment.start_on).to eq benefit_group_start
  end
end

shared_examples "an assignment that ends when the group ends", :shared => true do
  it "should be assigned ending on the benefit group end" do
    expect(benefit_group_assignment.end_on).to eq benefit_group_end
  end
end

shared_examples "an assignment that starts when the employee is hired", :shared => true do
  it "should be assigned starting on the hire date" do
    expect(benefit_group_assignment.start_on).to eq hired_on_date
  end
end

shared_examples "an assignment that ends when the employee is terminated", :shared => true do
  it "should be assigned ending on the termination date" do
    expect(benefit_group_assignment.end_on).to eq terminated_on_date
  end
end

describe EmployerCensus::BenefitGroupAssignment, "given a benefit group" do
  let(:benefit_group_start) { Date.new(2015, 1, 1) }
  let(:benefit_group_end) { Date.new(2015, 12, 31) }
  let(:census_employee) { EmployerCensus::Employee.new(:hired_on => hired_on_date, :terminated_on => terminated_on_date) }
  let(:roster_family) { EmployerCensus::EmployeeFamily.new(:census_employee => census_employee) }
  let(:benefit_group) { instance_double("BenefitGroup", :start_on => benefit_group_start, :end_on => benefit_group_end, :id => 1 ) }
  let(:benefit_group_assignment) {
    EmployerCensus::BenefitGroupAssignment.new_from_group_and_roster_family(benefit_group, roster_family)
  }

  describe "with an employee having no termination date" do
    let(:terminated_on_date) { nil }
    let(:hired_on_date) { Date.new(2014, 6, 5) }

    it "should have the correct employee_family" do
      expect(benefit_group_assignment.employee_family).to eq roster_family
    end

    it "should assign the benefit_group id to the benefit_group_assignment" do
      expect(benefit_group_assignment.benefit_group_id).to eq benefit_group.id
    end

    describe "and a hire date before the benefit group" do
      let(:hired_on_date) { Date.new(2014, 6, 5) }

      it_should_behave_like "an assignment that starts when the group starts"
      it_should_behave_like "an assignment that ends when the group ends"
    end

    describe "and a hire date during the benefit group" do
      let(:hired_on_date) { Date.new(2015, 6, 5) }
      it_should_behave_like "an assignment that starts when the employee is hired"
      it_should_behave_like "an assignment that ends when the group ends"
    end
  end

  describe "with an employee having a termination date after the benefit group end" do
    let(:terminated_on_date) { Date.new(2016, 1, 2) }

    describe "and a hire date before the benefit group" do
      let(:hired_on_date) { Date.new(2014, 6, 5) }
      it_should_behave_like "an assignment that starts when the group starts"
      it_should_behave_like "an assignment that ends when the group ends"
    end

    describe "and a hire date during the benefit group" do
      let(:hired_on_date) { Date.new(2015, 6, 5) }
      it_should_behave_like "an assignment that starts when the employee is hired"
      it_should_behave_like "an assignment that ends when the group ends"
    end
  end

  describe "with an employee having a termination date during the benefit group" do
    let(:terminated_on_date) { Date.new(2015, 6, 5) }

    describe "and a hire date before the benefit group" do
      let(:hired_on_date) { Date.new(2014, 6, 5) }
      it_should_behave_like "an assignment that starts when the group starts"
      it_should_behave_like "an assignment that ends when the employee is terminated"
    end

    describe "and a hire date during the benefit group" do
      let(:hired_on_date) { Date.new(2015, 6, 5) }
      it_should_behave_like "an assignment that starts when the employee is hired"
      it_should_behave_like "an assignment that ends when the employee is terminated"
    end
  end

end

describe EmployerCensus::BenefitGroupAssignment, type: :model do
  it { should validate_presence_of :benefit_group_id }
  it { should validate_presence_of :start_on }

  let(:benefit_group)           { FactoryGirl.create(:benefit_group) }
  let(:start_on)                { Date.current - 10.days }

  describe ".new" do
    let(:valid_params) do
      {
        benefit_group_id: benefit_group._id,
        start_on: start_on
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(EmployerCensus::BenefitGroupAssignment.create(**params).save).to be_falsey
      end
    end

    context "with no start on date" do
      let(:params) {valid_params.except(:start_on)}

      it "should raise" do
        expect(EmployerCensus::BenefitGroupAssignment.create(**params).errors[:start_on].any?).to be_truthy
      end
    end

    context "with no benefit group" do
      let(:params) {valid_params.except(:benefit_group_id)}

      it "should raise" do
        expect(EmployerCensus::BenefitGroupAssignment.create(**params).errors[:benefit_group_id].any?).to be_truthy
      end
    end

    context "with all valid parameters" do
      let(:params) {valid_params}
      let(:employee_family)           { FactoryGirl.create(:employer_census_family) }
      let(:benefit_group_assignment) do
        bga = EmployerCensus::BenefitGroupAssignment.new(**params)
        bga.employee_family = employee_family
        bga
      end

      it "should successfully save" do
        expect(benefit_group_assignment.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_benefit_group_assignment) do
          b = benefit_group_assignment
          b.save
          b
        end

        it "should be findable" do
          expect(EmployerCensus::BenefitGroupAssignment.find(saved_benefit_group_assignment._id)._id).to eq saved_benefit_group_assignment.id
        end
      end
    end
  end
end
