require 'rails_helper'

RSpec.describe PlanCostDecorator, dbclean: :after_each do
  let!(:plan_year)               { double("PlanYear", start_on: Date.today.beginning_of_year) }
  let!(:default_benefit_group)   { double("BenefitGroup", plan_year: plan_year) }
  let!(:default_plan)            { double("Plan", id: "default_plan_id") }
  let!(:default_reference_plan)  { double("Plan", id: "default_reference_plan_id") }
  let!(:plan_cost_decorator)     { PlanCostDecorator.new(plan, member_provider, benefit_group, reference_plan) }
  context "rating a large family" do
    let!(:plan)            {default_plan}
    let!(:benefit_group)   {default_benefit_group}
    let!(:reference_plan)  {default_plan}
    let!(:member_provider) {double("member_provider", class: HbxEnrollment, hbx_enrollment_members: [father, mother, one, two, three, four, five])}
    let!(:father)          {double("father", class: HbxEnrollmentMember, age_on_effective_date: 19, is_subscriber?: true , primary_relationship: "self")}
    let!(:mother)          {double("mother", class: HbxEnrollmentMember, age_on_effective_date: 20, is_subscriber?: false, primary_relationship: "spouse")}
    let!(:one)             {double("one"   , class: HbxEnrollmentMember, age_on_effective_date: 20, is_subscriber?: false, primary_relationship: "child")}
    let!(:two)             {double("two"   , class: HbxEnrollmentMember, age_on_effective_date: 18, is_subscriber?: false, primary_relationship: "child")}
    let!(:three)           {double("three" , class: HbxEnrollmentMember, age_on_effective_date: 13, is_subscriber?: false, primary_relationship: "child")}
    let!(:four)            {double("four"  , class: HbxEnrollmentMember, age_on_effective_date: 11, is_subscriber?: false, primary_relationship: "child")}
    let!(:five)            {double("five"  , class: HbxEnrollmentMember, age_on_effective_date: 4 , is_subscriber?: false, primary_relationship: "child")}
    def relationship_benefit_for(relationship)
      relationship_benefits = {
        "employee"   => double("employee_relationship_benefit", :offered? => true),
        "spouse" => double("spouse_relationship_benefit", :offered? => true),
        "child_under_26"  => double("child_relationship_benefit", :offered? => true)
      }
      raise "relationship_benefit_for(\"#{relationship}\") is not defined" unless relationship_benefits.keys.include?(relationship)
      relationship_benefits[relationship]
    end

    before do
      allow(benefit_group).to receive(:relationship_benefit_for) {|rel|relationship_benefit_for(rel)}
      allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * 1.0}
    end

    it "should be possible to construct a new plan cost decorator" do
      expect(plan_cost_decorator.class).to be PlanCostDecorator
    end

    it "should have a premium for father" do
      expect(plan_cost_decorator.premium_for(father)).to eq father.age_on_effective_date
    end

    it "should have a premium for mother" do
      expect(plan_cost_decorator.premium_for(mother)).to eq mother.age_on_effective_date
    end

    it "should have a premium for one" do
      expect(plan_cost_decorator.premium_for(one)).to eq one.age_on_effective_date
    end

    it "should have a premium for two" do
      expect(plan_cost_decorator.premium_for(two)).to eq two.age_on_effective_date
    end

    it "should have a premium for three" do
      expect(plan_cost_decorator.premium_for(three)).to eq three.age_on_effective_date
    end

    it "should have no premium for four" do
      expect(plan_cost_decorator.premium_for(four)).to eq 0.0
    end

    it "should have no premium for five" do
      expect(plan_cost_decorator.premium_for(five)).to eq 0.0
    end

    it "should have the right total premium" do
      expect(plan_cost_decorator.total_premium).to eq [father, mother, one, two, three].collect(&:age_on_effective_date).sum
    end
  end

  context "rating a census employee with many dependents" do
    let!(:plan)            {default_plan}
    let!(:benefit_group)   {default_benefit_group}
    let!(:reference_plan)  {default_plan}
    let!(:member_provider) {father}
    let!(:father)          {double("father", class: CensusEmployee , age_on: 19, employee_relationship: "employee", census_dependents: [mother, one, two, three, four, five])}
    let!(:mother)          {double("mother", class: CensusDependent, age_on: 20, employee_relationship: "spouse")}
    let!(:one)             {double("one"   , class: CensusDependent, age_on: 20, employee_relationship: "child_under_26")}
    let!(:two)             {double("two"   , class: CensusDependent, age_on: 18, employee_relationship: "child_under_26")}
    let!(:three)           {double("three" , class: CensusDependent, age_on: 13, employee_relationship: "child_under_26")}
    let!(:four)            {double("four"  , class: CensusDependent, age_on: 11, employee_relationship: "child_under_26")}
    let!(:five)            {double("five"  , class: CensusDependent, age_on: 4 , employee_relationship: "child_under_26")}
    def relationship_benefit_for(relationship)
      relationship_benefits = {
        "employee"   => double("employee_relationship_benefit", :offered? => true),
        "spouse" => double("spouse_relationship_benefit", :offered? => true),
        "child_under_26"  => double("child_relationship_benefit", :offered? => true)
      }
      raise "relationship_benefit_for(\"#{relationship}\") is not defined" unless relationship_benefits.keys.include?(relationship)
      relationship_benefits[relationship]
    end

    before do
      allow(benefit_group).to receive(:relationship_benefit_for) {|rel|relationship_benefit_for(rel)}
      allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * 1.0}
    end

    it "should be possible to construct a new plan cost decorator" do
      expect(plan_cost_decorator.class).to be PlanCostDecorator
    end

    it "should have a premium for father" do
      expect(plan_cost_decorator.premium_for(father)).to eq father.age_on
    end

    it "should have a premium for mother" do
      expect(plan_cost_decorator.premium_for(mother)).to eq mother.age_on
    end

    it "should have a premium for one" do
      expect(plan_cost_decorator.premium_for(one)).to eq one.age_on
    end

    it "should have a premium for two" do
      expect(plan_cost_decorator.premium_for(two)).to eq two.age_on
    end

    it "should have a premium for three" do
      expect(plan_cost_decorator.premium_for(three)).to eq three.age_on
    end

    it "should have no premium for four" do
      expect(plan_cost_decorator.premium_for(four)).to eq 0.0
    end

    it "should have no premium for five" do
      expect(plan_cost_decorator.premium_for(five)).to eq 0.0
    end

    it "should have the right total premium" do
      expect(plan_cost_decorator.total_premium).to eq [father, mother, one, two, three].collect(&:age_on).sum
    end
  end
end
