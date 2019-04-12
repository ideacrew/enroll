require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'remove_invalid_coverage_household_member')

describe RemoveInvalidCoverageHouseholdMember, dbclean: :after_each do

  let(:given_task_name) { 'remove_invalid_coverage_household_member' }
  let(:person) {FactoryBot.create(:person)}
  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:family_member) {FactoryBot.create(:family_member, family: family, is_active: true)}
  let(:coverage_household) { family.latest_household.coverage_households.first }
  let(:coverage_household_member_id) {coverage_household.coverage_household_members.first.id}
  subject { RemoveInvalidCoverageHouseholdMember.new(given_task_name, double(:current_scope => nil)) }
  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'remove invalid coverage household member' do

    before(:each) do
      ClimateControl.modify person_hbx_id: person.hbx_id, family_member_id: family_member.id, coverage_household_member_id: coverage_household_member_id, action: 'remove_invalid_chms' do 
      end
    end

    it 'should remove invalid coverage household memeber' do
        family.active_household.immediate_family_coverage_household.coverage_household_members.new(:is_subscriber => true, :family_member_id => '567678789')
        family.active_household.immediate_family_coverage_household.save
        size = family.active_household.immediate_family_coverage_household.coverage_household_members.size
        subject.migrate
        person.reload
        family.reload
        expect(family.active_household.immediate_family_coverage_household.coverage_household_members.size) == size-1
    end
      
    it 'should remove a family member to household' do
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
