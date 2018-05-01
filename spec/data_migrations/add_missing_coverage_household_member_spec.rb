require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_missing_coverage_household_member")

describe AddMissingCoverageHouseholdMember, dbclean: :after_each do

  let(:given_task_name) { "add_missing_coverage_household_member" }
  subject { AddMissingCoverageHouseholdMember.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "adding coverage household member", dbclean: :after_each do

    let!(:family) { FactoryGirl.create(:family, :with_family_members, person: person, people: family_members) }
    let(:person) { FactoryGirl.create(:person, person_relationships: family_relationships) }
    let(:family_members) { [person, spouse, child] }
    let(:spouse) { FactoryGirl.create(:person, dob: TimeKeeper.date_of_record - 50.years) }
    let(:child) { FactoryGirl.create(:person, dob: TimeKeeper.date_of_record - 27.years) }
    let(:family_relationships) { [PersonRelationship.new(relative: spouse, kind: "spouse"), PersonRelationship.new(relative: child, kind: "child")] }
    let(:coverage_household_member) { CoverageHouseholdMember.new(:family_member_id => family_member.id) }
    let(:coverage_household) { CoverageHousehold.new(:coverage_household_members => [coverage_household_member]) }

    before do
      allow(ENV).to receive(:[]).with('hbx_id').and_return person.hbx_id
      allow(ENV).to receive(:[]).with('relation').and_return "spouse"
    end

    it "should add a household" do
      subject.migrate
      expect(person.primary_family.active_household.immediate_family_coverage_household.coverage_household_members.size).to eq 2
    end
  end
end