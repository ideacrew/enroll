require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_family_member_from_coverage_household")

describe RemoveFamilyMemberFromCoverageHousehold, dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person, :with_ssn) }
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:family_member1) {FactoryBot.create(:family_member, family: family)}
  let!(:employee_role)  {FactoryBot.create(:employee_role, person: person)}
  

  let(:family_env_support) { {
    person_hbx_id: person.hbx_id,
    family_member_id: family_member1.id,
    person_first_name: family_member1.person.first_name,
    person_last_name: family_member1.person.last_name,
    action: "RemoveDuplicateMembers"
  }}

  let(:coverage_env_support) { {
    person_hbx_id: person.hbx_id,
    family_member_id: family_member1.id,
    action: "RemoveCoverageHouseholdMember"
  }}

 def with_modified_env(options, &block)
   ClimateControl.modify(options, &block)
 end

  let(:given_task_name) {"remove_family_member_from_coverage_household"}

  subject {RemoveFamilyMemberFromCoverageHousehold.new(given_task_name, double(:current_scope => nil))}

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "remove family member from coverage household", dbclean: :after_each do

    it "should remove a family member to household" do
      size = family.family_members.size
      with_modified_env coverage_env_support do 
        subject.migrate
        expect(family.reload.family_members.size).to eq size - 1
      end
    end
  end

  describe "removing duplicate family member" do

    it "should remove a family member based on first and last names" do
      size = family.family_members.size
      with_modified_env family_env_support do 
        subject.migrate
        expect(family.reload.family_members.size).to eq size - 1
      end
    end
  end
  
  describe "removing all duplicate family member" do
    let(:family_member_2) {FactoryBot.create(:family_member, family: family)}

    it "should remove a family member based on first and last names" do
      family_env_support[:person_first_name] = "#{family_member1.person.first_name},#{family_member_2.person.first_name}"
      family_env_support[:person_last_name] = "#{family_member1.person.last_name},#{family_member_2.person.last_name}"
      size = family.family_members.size
      with_modified_env family_env_support do 
        subject.migrate
        expect(family.reload.family_members.size).to eq size - 2
      end
    end
  end
end
