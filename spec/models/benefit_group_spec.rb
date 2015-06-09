require 'rails_helper'

describe BenefitGroup, type: :model do
  it { should validate_presence_of :relationship_benefits }
  it { should validate_presence_of :effective_on_kind }
  it { should validate_presence_of :terminate_on_kind }
  it { should validate_presence_of :effective_on_offset }
  it { should validate_presence_of :reference_plan_id }
  it { should validate_presence_of :employer_max_amt_in_cents }
end

describe BenefitGroup, dbclean: :after_each do
  context "an employer profile with families exists" do
    let!(:employer_profile) { FactoryGirl.create(:employer_profile)}
    let!(:families) do
      [1,2].collect do
        FactoryGirl.create(
          :employer_census_family,
          employer_profile: employer_profile
        )
      end.sort_by(&:id)
    end

    context "and a plan year exists" do
      let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_plan_year)}

      context "starting on 2/1/2015" do
        let(:start_plan_year) {Date.new(2015, 2, 1)}
        context "and a benefit_group_exists" do
          let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 30)}
          it "knows effective on for dates of hire" do
            year = 2015
            day = 15
            (0..11).each do |month_offset|
              date = (start_plan_year + 14.days) + month_offset.months
              expected_effective = (date + benefit_group.effective_on_offset.days).beginning_of_month.next_month
              expect(benefit_group.effective_on_for(date)).to eq expected_effective
            end
            date_of_hire = Date.new(2015, 1, 1)
            expected_effective = start_plan_year
            expect(benefit_group.effective_on_for(date_of_hire)).to eq expected_effective
            date_of_hire = Date.new(2015, 1, 15)
            expected_effective = Date.new(2015, 3, 1)
            expect(benefit_group.effective_on_for(date_of_hire)).to eq expected_effective
            date_of_hire = Date.new(2015, 1, 31)
            expected_effective = Date.new(2015, 4, 1)
            expect(benefit_group.effective_on_for(date_of_hire)).to eq expected_effective
          end
        end
      end
      context "starting on 4/1/2015" do
        let(:start_plan_year) {Date.new(2015, 4, 1)}
        context "and a benefit_group_exists" do
          let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 30)}
          it "knows effective on for dates of hire" do
            year = 2015
            day = 15
            (0..11).each do |month_offset|
              date = (start_plan_year + 0.days) + month_offset.months
              expected_effective = (date + benefit_group.effective_on_offset.days).beginning_of_month.next_month
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
  let!(:benefit_group)            { FactoryGirl.build(:benefit_group) }
  let!(:plan_year)                { FactoryGirl.build(:plan_year, benefit_groups: [benefit_group], start_on: Date.new(2015,1,1)) }
  let!(:employer_profile)         { FactoryGirl.create(:employer_profile, plan_years: [plan_year]) }
  let!(:benefit_group_assignment) { FactoryGirl.build(:employer_census_benefit_group_assignment, benefit_group: benefit_group) }
  let!(:families) do
    [1,2].collect do
      FactoryGirl.create(:employer_census_family,
            employer_profile: employer_profile,
            benefit_group_assignments: [benefit_group_assignment]
          )
    end.sort_by(&:id)
  end

  context "employee_census_families and benefit_group.employee_families" do
    let(:benefit_group_families) {benefit_group.employee_families.sort_by(&:id)}

    it "should include the same families" do
      expect(benefit_group_families).to eq families
    end
  end

  describe "should check if valid for family" do
    let(:terminated_on_date) { Date.new(2015, 7, 31) }
    let(:hired_on_date) { Date.new(2015, 6, 1) }
    let(:census_employee) { EmployerCensus::Employee.new(:hired_on => hired_on_date, :terminated_on => terminated_on_date) }
    let(:roster_family) { EmployerCensus::EmployeeFamily.new(:census_employee => census_employee) }

    context "given an invalid terminated and end date combo " do
       let(:terminated_on_date) { Date.new(2014, 1, 2) }

       it "is not assignable_to an employee fired before it starts" do
         expect(benefit_group.assignable_to?(roster_family)).to be_falsey
       end
     end

    context "given an invalid hired and start date combo" do
      let(:hired_on_date) { Date.new(2016, 6, 5) }

      it "is not assignable_to an employee hired after it ends" do
        expect(benefit_group.assignable_to?(roster_family)).to be_falsey
      end
    end

    it "should be valid if both dates fall inside plan year correctly" do
      expect(benefit_group.assignable_to?(roster_family)).to be_truthy
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

  it "write attribute by employer_max_amt_in_cents" do
    benefit_group.employer_max_amt_in_cents = "100"
    expect(benefit_group.premium_in_dollars).to be 100.to_f
  end

  context "simple benefit list" do
    let(:benefit_list){benefit_group.simple_benefit_list(50,20,200)}

    it "should have six item" do
      expect(benefit_list.size).to eq BenefitGroup::PERSONAL_RELATIONSHIP_KINDS.size
    end

    it "should have same employer_max_amount" do
      expect(benefit_list.map(&:employer_max_amt)).to eq Array.new(6, 200)
    end

    it "should have different premium_pct" do
      expect(benefit_list.map(&:premium_pct)).to eq [50,20,20,20,20,50]
    end

    it "should have different offered" do
      expect(benefit_list.map(&:offered)).to eq [true, true, true, true, true, false]
    end
  end
end
