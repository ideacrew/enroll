require 'rails_helper'

RSpec.describe UnassistedPlanCostDecorator, dbclean: :after_each do
  let!(:default_plan)            { double("Plan", id: "default_plan_id") }
  let!(:plan_cost_decorator)     { UnassistedPlanCostDecorator.new(plan, member_provider) }
  context "rating a large family" do
    let!(:plan)            {default_plan}
    let!(:member_provider) {double("member_provider", effective_on: 10.days.ago, hbx_enrollment_members: [father, mother, one, two, three, four, five])}
    let!(:father)          {double("father", class: HbxEnrollmentMember, age_on_effective_date: 19, is_subscriber?: true , primary_relationship: "self")}
    let!(:mother)          {double("mother", class: HbxEnrollmentMember, age_on_effective_date: 20, is_subscriber?: false, primary_relationship: "spouse")}
    let!(:one)             {double("one"   , class: HbxEnrollmentMember, age_on_effective_date: 20, is_subscriber?: false, primary_relationship: "child")}
    let!(:two)             {double("two"   , class: HbxEnrollmentMember, age_on_effective_date: 18, is_subscriber?: false, primary_relationship: "child")}
    let!(:three)           {double("three" , class: HbxEnrollmentMember, age_on_effective_date: 13, is_subscriber?: false, primary_relationship: "child")}
    let!(:four)            {double("four"  , class: HbxEnrollmentMember, age_on_effective_date: 11, is_subscriber?: false, primary_relationship: "child")}
    let!(:five)            {double("five"  , class: HbxEnrollmentMember, age_on_effective_date: 4 , is_subscriber?: false, primary_relationship: "child")}
    let!(:relationship_benefit_for) do
      {
        "self"   => double("self", :offered? => true),
        "spouse" => double("spouse", :offered? => true),
        "child"  => double("child", :offered? => true)
      }
    end

    before do
      allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * 1.0}
    end

    it "should be possible to construct a new plan cost decorator" do
      expect(plan_cost_decorator.class).to be UnassistedPlanCostDecorator
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
end
