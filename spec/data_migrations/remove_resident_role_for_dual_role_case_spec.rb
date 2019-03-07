require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_resident_role_for_dual_role_case")

describe RemoveResidentRole do

  let(:given_task_name) { "remove_resident_role_for_dual_role_case" }
  subject { RemoveResidentRoleForDualRoleCase.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "remove resident role for person with dual role case", dbclean: :after_each do
    let!(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_active_consumer_role, :with_resident_role, :with_active_resident_role) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }

    before :each do
      ENV['hbx_id'] = person.hbx_id.to_s
    end

    it "should remove the resident role for the person" do
      subject.migrate
      person.reload
      expect(person.resident_role).to be nil
    end
  end

  describe "no user found", dbclean: :after_each do
    before :each do
      ENV['hbx_id'] = 'some-hbx-id'
    end

    it "should raise an error if an hbx_id is not present" do
      expect{ subject.migrate }.to raise_error('No person found or more than one person found for hbx_id: some-hbx-id')
    end
  end  

  describe "given person is not primary person for any family", dbclean: :after_each do
    let!(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_active_consumer_role, :with_resident_role, :with_active_resident_role) }
    before :each do
      ENV['hbx_id'] = person.hbx_id.to_s
    end

    it "should raise an error if person is not primary member of the family" do
      expect{ subject.migrate }.to raise_error('Given person is not primary person for any family')
    end
  end  

  describe "if person's family has enrollments", dbclean: :after_each do
    let!(:person) { FactoryGirl.create(:person, :with_consumer_role ) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}

    before :each do
      ENV['hbx_id'] = person.hbx_id.to_s
    end

    it "should raise an error if person's family has enrollments" do
      expect{ subject.migrate }.to raise_error("This person's family has enrollments, please refactor the rake to handle family with enrollments")
    end
  end

  describe "if person's family has more than one family member", dbclean: :after_each do
    let!(:person) { FactoryGirl.create(:person, :with_consumer_role ) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member_and_dependent, person: person) }

    before :each do
      ENV['hbx_id'] = person.hbx_id.to_s
    end

    it "should raise an error if person has more family members" do
      expect{ subject.migrate }.to raise_error("This person's family has more than 1 family member, please refactor the rake to handle family with more members")
    end
  end

  describe "if person doesn't have any other active role", dbclean: :after_each do
    let!(:person) { FactoryGirl.create(:person, :with_consumer_role ) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }

    before :each do
      ENV['hbx_id'] = person.hbx_id.to_s
    end

    it "should raise an error if person doesn't have any other active role" do
      expect{ subject.migrate }.to raise_error("Cannot remove resident role as this person doesn't have any other active role")
    end
  end
end