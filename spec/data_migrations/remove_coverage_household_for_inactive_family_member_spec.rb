require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_coverage_household_member_for_inactive_family_member")

describe RemoveCoverageHouseHoldMemberForInactiveFamilyMember, dbclean: :after_each do

  let(:given_task_name) { "remove_coverage_household_member_for_inactive_family_member" }
  subject { RemoveCoverageHouseHoldMemberForInactiveFamilyMember.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "remove coverage household member for inactive family member", dbclean: :after_each do

    let(:person) { FactoryBot.create(:person) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:family_member){ FactoryBot.create(:family_member,family: family)}
    before do
      allow(ENV).to receive(:[]).with('person_hbx_id').and_return person.hbx_id
      allow(ENV).to receive(:[]).with('family_member_hbx_id').and_return family_member.hbx_id
    end

    it "should remove an inactive family member to household" do
      family.active_household.immediate_family_coverage_household.coverage_household_members.new(:is_subscriber => true, :family_member_id => "567678789")
      family.active_household.immediate_family_coverage_household.save
      size = family.active_household.immediate_family_coverage_household.coverage_household_members.size
      subject.migrate
      person.reload
      family.reload
      expect(family.active_household.immediate_family_coverage_household.coverage_household_members.size) == size-1
    end

    it "should not remove any family member from coverage household member" do
      size = family.active_household.immediate_family_coverage_household.coverage_household_members.size
      subject.migrate
      person.reload
      family.reload
      expect(family.active_household.immediate_family_coverage_household.coverage_household_members.size) == size
    end
  end
end
