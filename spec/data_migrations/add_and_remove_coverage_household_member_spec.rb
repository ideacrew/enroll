require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_and_remove_coverage_household_member")

describe AddAndRemoveCoverageHouseholdMember, dbclean: :after_each do

  let(:given_task_name) { "add_and_remove_coverage_household_member" }
  subject { AddAndRemoveCoverageHouseholdMember.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  let(:family) { FactoryGirl.create(:family, :with_primary_family_member_and_dependent)}

  before do
    allow(ENV).to receive(:[]).with('primary_hbx_id').and_return family.primary_applicant.person.hbx_id
    allow(ENV).to receive(:[]).with('family_member_ids').and_return family.primary_applicant.id
  end

  context "add coverage household member", dbclean: :after_each do

    before :each do
      allow(ENV).to receive(:[]).with('action').and_return "add_chm"
    end

    it "should add a new coverage household member record" do

      until family.active_household.coverage_households.map(&:coverage_household_members).flatten.blank?
        family.active_household.coverage_households.map(&:coverage_household_members).flatten.each do |chm|
          chm.destroy!
        end
      end
      expect(family.active_household.coverage_households.map(&:coverage_household_members).flatten.size).to eq 0
      subject.migrate
      family.active_household.reload
      expect(family.active_household.coverage_households.map(&:coverage_household_members).flatten.size).to eq 1
    end


    it "should not add a coverage household member record if already exists" do
      expect(family.active_household.coverage_households.map(&:coverage_household_members).flatten.size).to eq 3
      subject.migrate
      family.active_household.reload
      expect(family.active_household.coverage_households.map(&:coverage_household_members).flatten.size).to eq 3
    end
  end

  context "remove coverage household member", dbclean: :after_each do

    before :each do
      allow(ENV).to receive(:[]).with('action').and_return "remove_chm"
    end

    it "should remove coverage household member record" do
      expect(family.active_household.coverage_households.map(&:coverage_household_members).flatten.size).to eq 3
      subject.migrate
      family.active_household.reload
      expect(family.active_household.coverage_households.map(&:coverage_household_members).flatten.size).to eq 2
    end
  end

  context "remove coverage household member for an invalid family member", dbclean: :after_each do

    before :each do
      allow(ENV).to receive(:[]).with('invalid_family_members').and_return "true"
      allow(ENV).to receive(:[]).with('family_member_ids').and_return "random_id"
      allow(ENV).to receive(:[]).with('action').and_return nil
    end

    it "should remove coverage household member record" do
      expect(family.active_household.coverage_households.map(&:coverage_household_members).flatten.size).to eq 3
      family.active_household.coverage_households.map(&:coverage_household_members).flatten.each do |chm|
        next if chm.is_subscriber
        chm.update_attribute(:family_member_id, "random_id")
      end
      subject.migrate
      family.active_household.reload
      expect(family.active_household.coverage_households.map(&:coverage_household_members).flatten.size).to eq 1
    end
  end
end
