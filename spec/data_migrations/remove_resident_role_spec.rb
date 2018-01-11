require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_resident_role")

describe RemoveResidentRole do

  let(:given_task_name) { "remove_resident_role" }
  subject { RemoveResidentRole.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "remove resident role for person with no enrollments" do
    let!(:person1) { FactoryGirl.create(:person, :with_resident_role, id:'58e3dc7dqwewqewqe') }
    let!(:person2) { FactoryGirl.create(:person, :with_consumer_role) }
    let!(:primary_family) { FactoryGirl.create(:family, :with_primary_family_member, person: person2) }
    let!(:ivl_enrollment) do
      FactoryGirl.create(:hbx_enrollment, :individual_unassisted, household: primary_family.active_household,
        kind: 'coverall', consumer_role_id: person2.consumer_role.id)
    end
    let!(:r_role) { FactoryGirl.create(:resident_role, person: person2) }

    before(:each) do
      allow(ENV).to receive(:[]).with("coverall_ids").and_return('dfrwrwe23r,58e3dc7dqwewqewqe')
      allow(ENV).to receive(:[]).with("p_to_fix_id").and_return(nil)

      subject.migrate
      person1.reload
      person2.reload
    end

    it "deletes the resident role for person2 and not for person1" do
      expect(person1.resident_role).not_to be_nil
      expect(person2.resident_role).to be(nil)
      expect(person2.primary_family.active_household.hbx_enrollments.first.kind).to eq("individual")
      expect(person2.primary_family.active_household.hbx_enrollments.first.resident_role_id).to be(nil)
      expect(person2.primary_family.active_household.hbx_enrollments.first.consumer_role_id).to eq(person2.consumer_role.id)
      expect(person2.consumer_role).not_to be_nil
    end

    #it "sets the kind attribute on the enrollment for person2 to individual" do
     # expect(person2.primary_family.active_household.hbx_enrollments.first.kind).to eq("individual")
    #end

    #it "removes the reference to the destroyed resident role on the enrollment" do
     # expect(person2.primary_family.active_household.hbx_enrollments.first.resident_role_id).to be(nil)
    #end

    #it "sets the enrollment to reference the new consumer role created for the person" do
     # expect(person2.primary_family.active_household.hbx_enrollments.first.consumer_role_id).to eq(person2.consumer_role.id)
    #end
  end

  describe "remove resident role for person with coverall enrollment and no consumer_role" do
    let!(:person1) { FactoryGirl.create(:person, :with_resident_role, ssn: 111111111)}
    let!(:primary_family) { FactoryGirl.create(:family, :with_primary_family_member, person: person1) }
    let!(:ivl_enrollment) do
      FactoryGirl.create(:hbx_enrollment, :individual_unassisted, household: primary_family.active_household,
        kind: 'coverall', resident_role_id: person1.resident_role.id)
    end
    let!(:ee_role) { FactoryGirl.create(:employee_role, person: person1) }

    before(:each) do
      allow(ENV).to receive(:[]).with("coverall_ids").and_return('dfrwrwe23r,58e3dc7dqwewqewqe')
      allow(ENV).to receive(:[]).with("p_to_fix_id").and_return(nil)

      subject.migrate
      person1.reload
    end

    it "deletes the resident role for person1 and creates a consumer role as well" do
      expect(person1.consumer_role).not_to be_nil
      expect(person1.resident_role).to be(nil)
      expect(person1.primary_family.active_household.hbx_enrollments.first.kind).to eq("individual")
      expect(person1.primary_family.active_household.hbx_enrollments.first.resident_role_id).to be(nil)
      expect(person1.primary_family.active_household.hbx_enrollments.first.consumer_role_id).to eq(person1.consumer_role.id)
    end
  end
end