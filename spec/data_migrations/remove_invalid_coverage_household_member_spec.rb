require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_invalid_coverage_household_member")

describe RemoveInvalidCoverageHouseholdMember, dbclean: :after_each do

  let(:given_task_name) { "remove_invalid_coverage_household_member" }
  subject { RemoveInvalidCoverageHouseholdMember.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "remove invalid coverage household member" do
    let(:person) {FactoryBot.create(:person)}
    let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:family_member) {FactoryBot.create(:family_member, family: family, is_active: true)}
    let(:coverage_household) { family.latest_household.coverage_households.first }
    before do
      coverage_household_member_id = coverage_household.coverage_household_members.first.id
      allow(ENV).to receive(:[]).with('person_hbx_id').and_return person.hbx_id
      allow(ENV).to receive(:[]).with('family_member_id').and_return family_member.id
      allow(ENV).to receive(:[]).with('coverage_household_member_id').and_return coverage_household_member_id
      allow(ENV).to receive(:[]).with('action').and_return('remove_invalid_chms')
    end

      it "should remove invalid coverage household memeber" do
        family.active_household.immediate_family_coverage_household.coverage_household_members.new(:is_subscriber => true, :family_member_id => "567678789")
        family.active_household.immediate_family_coverage_household.save
        size = family.active_household.immediate_family_coverage_household.coverage_household_members.size
        subject.migrate
        person.reload
        family.reload
        expect(family.active_household.immediate_family_coverage_household.coverage_household_members.size) == size-1
      end
      
      it "should remove a family member to household" do
      size = family.households.first.coverage_households.where(:is_immediate_family => true).first.coverage_household_members.size
      family.households.first.coverage_households.where(:is_immediate_family => false).first.coverage_household_members.each do |chm|
        chm.delete
        subject.migrate
        family.households.first.reload
        expect(family.households.first.coverage_households.where(:is_immediate_family => true).first.coverage_household_members.count).not_to eq(size)
      end
    end
  end
end