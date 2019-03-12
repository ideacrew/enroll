require 'rails_helper'

RSpec.describe PlanCostDecorator, dbclean: :after_each do
  let!(:plan_year)               { double("PlanYear", start_on: Date.today.beginning_of_year) }
  let!(:default_benefit_group)   { double("BenefitGroup", plan_year: plan_year) }  
  let!(:benefit_group)   {default_benefit_group}
  let!(:member_provider) {double("member_provider", class: HbxEnrollment, hbx_enrollment_members: [father, mother, one, two, three, four, five])}
  let!(:father)          {double("father", dob: 55.years.ago, age_on: 55, employee_relationship: "self")}
  let!(:mother)          {double("mother", dob: 45.years.ago, age_on: 45, employee_relationship: "spouse")}
  let!(:one)             {double("one"   , dob: 20.years.ago, age_on: 20, employee_relationship: "child")}
  let!(:two)             {double("two"   , dob: 18.years.ago, age_on: 18, employee_relationship: "child")}
  let!(:three)           {double("three" , dob: 13.years.ago, age_on: 13, employee_relationship: "child")}
  let!(:four)            {double("four"  , dob: 11.years.ago, age_on: 11, employee_relationship: "child")}
  let!(:five)            {double("five"  , dob: 4.years.ago , age_on: 4 , employee_relationship: "child")}
  let!(:relationship_benefit_for) do
    {
      "self"   => double("self", :offered? => true),
      "spouse" => double("spouse", :offered? => true),
      "child"  => double("child", :offered? => true)
    }
  end

  context "rating a large family" do

    context "for health coverage" do 
      let!(:plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'shop') }
      let!(:reference_plan)  {  FactoryGirl.create(:plan, :with_premium_tables, market: 'shop') }

      let!(:plan_cost_decorator)     { PlanCostDecorator.new(plan, member_provider, benefit_group, reference_plan) }

      before do
        allow(benefit_group).to receive(:relationship_benefit_for) {|rel|relationship_benefit_for[rel]}
        allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * 1.0}
      end

      it "should be possible to construct a new plan cost decorator" do
        expect(plan_cost_decorator.class).to be PlanCostDecorator
      end

      it "should have a premium for father" do
        expect(plan_cost_decorator.premium_for(father)).to eq 55.0
      end

      it "should have a premium for mother" do
        expect(plan_cost_decorator.premium_for(mother)).to eq 45.0
      end

      it "should have a premium for one" do
        expect(plan_cost_decorator.premium_for(one)).to eq 20.0
      end

      it "should have a premium for two" do
        expect(plan_cost_decorator.premium_for(two)).to eq 18.0
      end

      it "should have a premium for three" do
        expect(plan_cost_decorator.premium_for(three)).to eq 13.0
      end

      it "should have no premium for four" do
        expect(plan_cost_decorator.premium_for(four)).to eq 0.0
      end

      it "should have no premium for five" do
        expect(plan_cost_decorator.premium_for(five)).to eq 0.0
      end

      it "should have the right total premium" do
        expect(plan_cost_decorator.total_premium).to eq [55, 45, 20, 18, 13].sum
      end

      it "round premium contribution of a member" do
        allow(BigDecimal).to receive_message_chain(:new, :round, :to_f).and_return("13.65")
        expect(plan_cost_decorator.premium_for(three)).to eq "13.65"
      end
    end

    context "for dental coverage" do 

      let!(:plan) { FactoryGirl.create(:plan, :with_dental_coverage, :with_premium_tables, market: 'shop') }
      let!(:reference_plan)  {  FactoryGirl.create(:plan, :with_dental_coverage, :with_premium_tables, market: 'shop') }

      let!(:plan_cost_decorator)     { PlanCostDecorator.new(plan, member_provider, benefit_group, reference_plan) }

      before do
        allow(benefit_group).to receive(:dental_relationship_benefit_for) {|rel|relationship_benefit_for[rel]}
        allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * 1.0}
      end

      it "should be possible to construct a new plan cost decorator" do
        expect(plan_cost_decorator.class).to be PlanCostDecorator
      end

      it "should have a premium for father" do
        expect(plan_cost_decorator.premium_for(father)).to eq 55.0
      end

      it "should have a premium for mother" do
        expect(plan_cost_decorator.premium_for(mother)).to eq 45.0
      end

      it "should have a premium for one" do
        expect(plan_cost_decorator.premium_for(one)).to eq 20.0
      end

      it "should have a premium for two" do
        expect(plan_cost_decorator.premium_for(two)).to eq 18.0
      end

      it "should have a premium for three" do
        expect(plan_cost_decorator.premium_for(three)).to eq 13.0
      end

      it "should have a premium for four" do
        expect(plan_cost_decorator.premium_for(four)).to eq 11.0
      end

      it "should have a premium for five" do
        expect(plan_cost_decorator.premium_for(five)).to eq 4.0
      end

      it "should have the right total premium" do
        expect(plan_cost_decorator.total_premium).to eq [55, 45, 20, 18, 13, 11, 4].sum
      end

      it "round premium contribution of a member" do
        allow(BigDecimal).to receive_message_chain(:new, :round, :to_f).and_return("13.65")
        expect(plan_cost_decorator.premium_for(three)).to eq "13.65"
      end
    end
  end

  describe ".relationship_benefit_for" do
    let(:health_plan) {FactoryGirl.build :plan, :with_premium_tables, coverage_kind: "health"}
    let(:dental_plan) {FactoryGirl.build :plan, :with_premium_tables, coverage_kind: "dental"}


    context "while estimating BQT, Estimated Maximum for monthly employer cost" do
      let(:bqt_benefit_group) { FactoryGirl.build(:sponsored_benefits_benefit_applications_benefit_group) }
      let(:plan_design_census_employee) {FactoryGirl.build :plan_design_census_employee}
      let(:employee_relation_benefit) {bqt_benefit_group.relationship_benefits.where(relationship: "employee").first}
      let(:relation_benefits) {FactoryGirl.build :relationship_benefit}

      it "should find relationship for employee when employee_relationship is 'self'" do
        bqt_benefit_group.dental_relationship_benefits << relation_benefits
        [health_plan, dental_plan].each do |plan|
          plan_cost_decorator = PlanCostDecorator.new(nil, plan_design_census_employee, bqt_benefit_group, plan)
          expect(plan_cost_decorator.relationship_for(plan_design_census_employee)).to eq "employee"

          if plan.coverage_kind == "health"
            expect(plan_cost_decorator.relationship_benefit_for(plan_design_census_employee)).to eq employee_relation_benefit
          else
            expect(plan_cost_decorator.relationship_benefit_for(plan_design_census_employee)).to eq relation_benefits
          end

        end
      end
    end

    context "while estimating for enroll employee" do
      let(:enroll_benefit_group) {  FactoryGirl.build(:benefit_group, :with_valid_dental)}
      let(:census_employee) { FactoryGirl.build :census_employee }
      let(:health_employee_relation_benefit) { enroll_benefit_group.relationship_benefits.where(relationship: "employee").first}
      let(:dental_employee_relation_benefit) { enroll_benefit_group.dental_relationship_benefits.where(relationship: "employee").first }

      it "should  find relationship for employee when employee_relationship is 'self'" do
        [health_plan, dental_plan].each do |plan|
          plan_cost_decorator = PlanCostDecorator.new(nil, census_employee, enroll_benefit_group, plan)
          expect(plan_cost_decorator.relationship_for(census_employee)).to eq "employee"

          if plan.coverage_kind == "health"
            expect(plan_cost_decorator.relationship_benefit_for(census_employee)).to eq health_employee_relation_benefit
          else
            expect(plan_cost_decorator.relationship_benefit_for(census_employee)).to eq dental_employee_relation_benefit
          end

        end

      end
    end

    context "while estimating DC Quote for quote Benefit Group" do
      let(:quote_benefit_group) {   FactoryGirl.build :quote_benefit_group, :with_valid_dental }
      let(:census_employee) { FactoryGirl.build :census_employee }
      let(:health_quote_employee_relation_benefit) { quote_benefit_group.quote_relationship_benefits.where(relationship: "employee").first}
      let(:dental_quote_employee_relation_benefit) { quote_benefit_group.quote_dental_relationship_benefits.where(relationship: "employee").first }

      it "should  find relationship for employee when employee_relationship is 'self'" do

        [health_plan, dental_plan].each do |plan|
          plan_cost_decorator = PlanCostDecorator.new(nil, census_employee, quote_benefit_group, plan)
          expect(plan_cost_decorator.relationship_for(census_employee)).to eq "employee"

          if plan.coverage_kind == "health"
            expect(plan_cost_decorator.relationship_benefit_for(census_employee)).to eq health_quote_employee_relation_benefit
          else
            expect(plan_cost_decorator.relationship_benefit_for(census_employee)).to eq dental_quote_employee_relation_benefit
          end

        end
      end

    end
  end
end
