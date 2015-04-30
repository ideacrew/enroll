require 'rails_helper'

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