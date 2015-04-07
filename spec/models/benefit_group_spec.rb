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

describe BenefitGroup, type: :model do
  context "an employer profile with families exists" do
    let!(:employer_profile) {FactoryGirl.create(:employer_profile)}
    let!(:families) do
      [1,2].collect do
        FactoryGirl.create(
          :employer_census_family,
          employer_profile: employer_profile,
          plan_year: plan_year
        )
      end.sort_by(&:id)
    end
    context "and a plan year exists" do
      let(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_plan_year)}

      context "starting on 2/1/2015" do
        let(:start_plan_year) {Date.new(2015, 2, 1)}
        context "and a benefit_group_exists" do
          let!(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 30)}
          it "knows effective on for dates of hire" do
            year = 2015
            day = 15
            (0..11).each do |month_offset|
              date = (start_plan_year + 14.days) + month_offset.months
              expected_effective = (date + benefit_group.effective_on_offset.days).beginning_of_month
              expect(benefit_group.effective_on_for(date)).to eq expected_effective
            end
            date_of_hire = Date.new(2015, 1, 1)
            expected_effective = start_plan_year
            expect(benefit_group.effective_on_for(date_of_hire)).to eq expected_effective
            date_of_hire = Date.new(2015, 1, 31)
            expected_effective = Date.new(2015, 3, 1)
            expect(benefit_group.effective_on_for(date_of_hire)).to eq expected_effective
          end
        end
      end
      context "starting on 4/1/2015" do
        let(:start_plan_year) {Date.new(2015, 4, 1)}
        context "and a benefit_group_exists" do
          let!(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 30)}
          it "knows effective on for dates of hire" do
            year = 2015
            day = 15
            (0..11).each do |month_offset|
              date = (start_plan_year + 0.days) + month_offset.months
              expected_effective = (date + benefit_group.effective_on_offset.days).beginning_of_month
              expect(benefit_group.effective_on_for(date)).to eq expected_effective
            end
            date_of_hire = Date.new(2010, 01, 01)
            expected_effective = start_plan_year
            expect(benefit_group.effective_on_for(date_of_hire)).to eq expected_effective
          end
        end
      end
    end
  end
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
    expect(benefit_group.elected_plan_ids).to include(benefit_group.reference_plan_id)
  end

  it "knows effective on for dates of hire" do
    year = 2015
    day = 15
    (1..12).each do |month|
      date = Date.new(year, month, day)
      expect(benefit_group.effective_on_for(date)).to eq date
    end
  end

  it "verifies each elected plan is a plan" do
    expect do
      benefit_group.elected_plan_ids.each do |plan_id|
        expect(Plan.find(plan_id)).to be_instance_of Plan
      end
    end.not_to raise_exception
  end

  it "verifies premium_pct_as_integer is > 50%" do
    invalid = FactoryGirl.build(:benefit_group, plan_year: plan_year, premium_pct_as_int: 40)
    expect(invalid.valid?).to be false
  end
end
