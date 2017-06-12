require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_dental_relationship_benefits")

describe "UpdateDentalRelationshipBenefits", dbclean: :after_each do

  let(:given_task_name) { "update_dental_relationship_benefits" }
  subject { UpdateDentalRelationShipBenefits.new(given_task_name, double(:current_scope => nil)) }


  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing plan year's state" do

    let(:benefit_group) { FactoryGirl.create(:benefit_group)}

   let(:dental_relationship_benefit) do
      [
          RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
          RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75),
          RelationshipBenefit.new(offered: true, relationship: :child_under_26, premium_pct: 50)
      ]
    end

    let(:plan_year) { FactoryGirl.build(:plan_year)}

    let(:employer_profile) { FactoryGirl.create(:employer_profile, plan_years:[plan_year])}
    let(:organization) { FactoryGirl.create(:organization,employer_profile:employer_profile)}

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(plan_year.start_on)
      allow(ENV).to receive(:[]).with("benefit_group_id").and_return(benefit_group.id)
      allow(ENV).to receive(:[]).with("relationship").and_return('spouse')
      allow(benefit_group).to receive_message_chain(:dental_relationship_benefits).and_return(dental_relationship_benefit)
    end

    it "should change person relationships kind" do
      allow(plan_year).to receive(:benefit_groups).and_return(benefit_group)
      allow(benefit_group).to receive(:dental_relationship_benefits).and_return([dental_relationship_benefit])
      UpdateDentalRelationShipBenefits.migrate(organization.fein,plan_year.start_on,benefit_group.id,"spouse")
    end

  end
end
