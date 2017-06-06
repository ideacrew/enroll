require "rails_helper"

describe BenefitGroup, "being asked for a group size rating factor" do
  let(:carrier_profile_id) { double }
  let(:plan) { instance_double(Plan, :carrier_profile_id => carrier_profile_id) }
  let(:plan_option_kind) { "sole_source" }
  let(:group_size_of_1_factor) { double }
  let(:plan_year) { PlanYear.new(:start_on => Date.new(2015, 2, 1)) }
  
  subject { BenefitGroup.new(:plan_option_kind => plan_option_kind, :plan_year => plan_year) }

  describe "when the rating model is 'simple'" do
    before(:each) do
      allow(subject).to receive(:use_simple_employer_calculation_model?).and_return(true)
    end

    it "provides a factor of 1.0" do
      expect(subject.group_size_factor_for(plan)).to eq 1.0
    end
  end

  describe "when the complex rating model is in use" do
    before(:each) do
      allow(subject).to receive(:use_simple_employer_calculation_model?).and_return(false)
    end

    describe "when the plan year is not sole-source" do
      let(:plan_option_kind) { "metal_level" }

      before :each do
        allow(EmployerGroupSizeRatingFactorSet).to receive(:value_for).with(carrier_profile_id, 2015, 1).and_return(group_size_of_1_factor)
      end

      it "returns the value for a group size of 1" do
        expect(subject.group_size_factor_for(plan)).to eq group_size_of_1_factor
      end
    end

    describe "when the plan year is sole source, and the group size is 3" do
      before :each do
        allow(EmployerGroupSizeRatingFactorSet).to receive(:value_for).with(carrier_profile_id, 2015, 3).and_return(group_size_of_1_factor)
        allow(subject).to receive(:group_size_count).and_return(3)
      end

      it "returns the value for a group size of 3" do
        expect(subject.group_size_factor_for(plan)).to eq group_size_of_1_factor
      end
    end
  end
end

describe BenefitGroup, "for a plan year which should estimate the group size" do
  let(:plan_year) { PlanYear.new(:start_on => Date.new(2015, 2, 1)) }

  let(:census_employees) do
    [
      instance_double(CensusEmployee, :expected_to_enroll? => true),
      instance_double(CensusEmployee, :expected_to_enroll? => true),
      instance_double(CensusEmployee, :expected_to_enroll? => false)
    ]
  end
  
  subject { BenefitGroup.new(:plan_year => plan_year) }

  before :each do
    allow(plan_year).to receive(:estimate_group_size?).and_return(true)
    allow(CensusEmployee).to receive(:find_all_by_benefit_group).with(subject).and_return(census_employees)
  end

  it "provides the group_size_count based on the employees expected to enroll" do
    expect(subject.group_size_count).to eq 2
  end
end

describe BenefitGroup, "for a plan year which should NOT estimate the group size" do
  let(:plan_year) { PlanYear.new(:start_on => Date.new(2015, 2, 1)) }
  let(:employee_enrollment_count) { double }
  
  subject { BenefitGroup.new(:plan_year => plan_year) }

  before :each do
    allow(plan_year).to receive(:estimate_group_size?).and_return(false)
  end

  it "provides the group_size_count based on the employees expected to enroll" do
    expect(subject.group_size_count).to eq employee_enrollment_count
  end
end
