require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "match_coverage_household_with_family_member")

describe MatchCoverageHouseholdWithFamilyMember, dbclean: :after_each do
  before do
    DatabaseCleaner.clean
  end

  let(:given_task_name) { "match_coverage_household_with_family_member" }
  subject { MatchCoverageHouseholdWithFamilyMember.new(given_task_name, double(:current_scope => nil)) }
  let!(:family11) { FactoryGirl.create(:family, :with_primary_family_member_and_dependent)}
  let!(:person11) { family11.primary_applicant.person }

  before :each do
    person11.update_attributes!(hbx_id: "1009988")
    @immediate_coverage_household = family11.active_household.immediate_family_coverage_household
    @extended_coverage_household = family11.active_household.extended_family_coverage_household
  end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "matching coverage household with family members", dbclean: :after_each do

    context "for a case where hbx_id is wrong" do
      before :each do
        allow(ENV).to receive(:[]).with('hbx_id').and_return "1009987"
      end

      it "should throw an error" do
        expect {subject.migrate}.to raise_error(RuntimeError, "More/No people found with the given hbx_id: 1009987")
      end
    end

    context "for a case where hbx_id is correct" do
      before :each do
        person11.person_relationships.each { |pr| pr.update_attributes!(kind: "parent") }
        allow(ENV).to receive(:[]).with('hbx_id').and_return person11.hbx_id
      end

      it "should sort coverage_household_members as per relationships" do
        expect(@immediate_coverage_household.coverage_household_members.count).to eq 3
        expect(@extended_coverage_household.coverage_household_members.count).to eq 0
        subject.migrate
        family11.active_household.coverage_households.map(&:reload)
        expect(@immediate_coverage_household.coverage_household_members.count).to eq 1
        expect(@extended_coverage_household.coverage_household_members.count).to eq 2
      end
    end
  end
end