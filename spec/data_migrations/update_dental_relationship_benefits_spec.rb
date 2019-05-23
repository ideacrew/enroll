require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_dental_relationship_benefits")

describe "UpdateDentalRelationshipBenefits", dbclean: :after_each do

  let(:given_task_name) { "update_dental_relationship_benefits" }
  subject { UpdateDentalRelationshipBenefits.new(given_task_name, double(:current_scope => nil)) }

  after :each do
    ["fein", "plan_year_start_on", "benefit_group_id", "relationship"].each do |env_variable|
      ENV[env_variable] = nil
    end
  end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "change person relationships kind" do
    let!(:benefit_group)  {FactoryBot.create(:benefit_group, :with_valid_dental)}

    around do |example|
     ClimateControl.modify fein: benefit_group.employer_profile.organization.fein,
                           plan_year_start_on: benefit_group.plan_year.start_on.to_s,
                           benefit_group_id: benefit_group.id,
                           relationship: 'spouse'  do
       example.run
     end
    end

    it "should change person relationships kind" do
      subject.migrate
      benefit_group.reload
      expect(benefit_group.dental_relationship_benefits.where(relationship:'spouse').first.offered).to eq false
    end
  end
end
