require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "cobra_renewal_enrollments_premium")

describe "UpdateDentalRelationshipBenefits", dbclean: :after_each do

  let(:given_task_name) { "cobra_renewal_enrollments_premium" }
  subject { CobraRenewalEnrollmentsPremium.new(given_task_name, double(:current_scope => nil)) }


  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "change member primary relationship self" do
    let!(:family) { FactoryGirl.create(:family, :with_family_members, person: person, people: [person]) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role)}
    let!(:benefit_group) { FactoryGirl.create(:benefit_group)}
     let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    before(:each) do
      allow(ENV).to receive(:[]).with('hbx_id').and_return person.hbx_id
       allow(ENV).to receive(:[]).with('hbx_id1').and_return hbx_enrollment.hbx_id
    end

    it "should change person relationships kind" do
      expect(hbx_enrollment.hbx_enrollment_members.count).to eq 0
      subject.migrate
      hbx_enrollment.reload
     expect(hbx_enrollment.hbx_enrollment_members.count).to eq 1
    end
  end
end