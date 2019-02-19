require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_consumer_role_for_family_member")

describe AddConsumerRoleForFamilyMember, dbclean: :after_each do

  let(:given_task_name) { "add_consumer_role_for_family_member" }
  subject { AddConsumerRoleForFamilyMember.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "add consumer role for family member", dbclean: :after_each do

    let!(:person) { FactoryGirl.create(:person, :with_family) }
    let!(:dependent) { FactoryGirl.create(:person) }
    let!(:dependent_family_member) { FactoryGirl.create(:family_member, family: person.primary_family ,person: dependent)}
    let!(:coverage_household_member2) { coverage_household.coverage_household_members.new(:family_member_id => dependent_family_member.id) }
    let(:primary_family){person.primary_family}
    let(:coverage_household){person.primary_family.active_household.immediate_family_coverage_household}


    it "should add a consumer role for primary applicant family member " do
      primary_family_member=primary_family.family_members.where(is_primary_applicant:true).first
      allow(ENV).to receive(:[]).with('family_member_id').and_return primary_family_member.id
      allow(ENV).to receive(:[]).with('is_applicant').and_return "true"
      expect(person.consumer_role).to eq nil
      subject.migrate
      person.reload
      dependent.reload
      expect(person.consumer_role).not_to eq nil
    end

    it "should add a consumer role for dependent family member " do
      allow(ENV).to receive(:[]).with('family_member_id').and_return dependent_family_member.id
      allow(ENV).to receive(:[]).with('is_applicant').and_return "false"
      expect(dependent.consumer_role).to eq nil
      subject.migrate
      person.reload
      dependent.reload
      expect(dependent.consumer_role).not_to eq nil
    end
  end
end
