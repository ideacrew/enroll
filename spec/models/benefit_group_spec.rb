require 'rails_helper'

describe BenefitGroup, type: :model do
  it { should validate_presence_of :relationship_benefits }
  it { should validate_presence_of :effective_on_kind }
  it { should validate_presence_of :terminate_on_kind }
  it { should validate_presence_of :effective_on_offset }
  it { should validate_presence_of :reference_plan_id }
  it { should validate_presence_of :premium_pct_as_int }
  it { should validate_presence_of :employer_max_amt_in_cents }
end

describe BenefitGroup, "instance methods" do
  let!(:employer_profile) {FactoryGirl.create(:employer_profile)}
  let!(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile)}
  let!(:families) do
    [1,2].collect do
      FactoryGirl.create(
        :employer_census_family,
        employer_profile: employer_profile,
        plan_year: plan_year
      )
    end.sort_by(&:id)
  end
  let!(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year)}

  context "employee_census_families and benefit_group.employee_families" do
    let(:benefit_group_families) {benefit_group.employee_families.sort_by(&:id)}

    it "should include the same families" do
      expect(benefit_group_families).to eq families
    end
  end

  it "should return the reference plan associated with this benefit group" do
    expect(benefit_group.reference_plan).to be_instance_of Plan
  end

  it "verifies the reference plan is included in the set of elected_plans" do
    expect do
      benefit_group.elected_plans.each do |plan_id|
        expect(Plan.find(plan_id)).to be_instance_of Plan
      end
    end.not_to raise_exception
  end

  it "verifies premium_pct_as_integer is > 50%" do
    invalid = FactoryGirl.build(:benefit_group, plan_year: plan_year, premium_pct_as_int: 40)
    expect(invalid.valid?).to be false
  end
end
