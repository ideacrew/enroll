require "rails_helper"
require 'csv'
require File.join(Rails.root, "app", "reports", "hbx_reports", "edi_enrollment_termination_report")

describe TerminatedHbxEnrollments do

  let(:given_task_name) { "enrollment_termination_on" }
  let(:person1) {FactoryGirl.create(:person,
                                    :with_consumer_role,
                                    first_name: "F_name1",
                                    last_name:"L_name1")}
  let(:person2) {FactoryGirl.create(:person,
                                    :with_employee_role,
                                    first_name: "Lis2",
                                    last_name:"L_name1")}
  let(:hbx_enrollment_member1){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family1.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let(:hbx_enrollment_member2){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family2.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  subject { TerminatedHbxEnrollments.new(given_task_name, double(:current_scope => nil)) }
  let(:family1) { FactoryGirl.create(:family, :with_primary_family_member, :person => person1)}
  let(:hbx_enrollment1) { FactoryGirl.create(:hbx_enrollment,
                                             household: family1.active_household,
                                             aasm_state:"coverage_terminated",
                                             hbx_enrollment_members: [hbx_enrollment_member1],
                                             termination_submitted_on: Date.yesterday.midday)}
  let(:family2) { FactoryGirl.create(:family, :with_primary_family_member, :person => person2)}
  let(:hbx_enrollment2) { FactoryGirl.create(:hbx_enrollment,
                                             household: family2.active_household,
                                             aasm_state:"coverage_termination_pending",
                                             hbx_enrollment_members: [hbx_enrollment_member2],
                                             termination_submitted_on: Date.yesterday.midday)}

  describe "correct data input" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end

    it "has the families with hbx_enrollments and correct states" do
      expect(hbx_enrollment1.coverage_terminated?).to be_truthy
      expect(hbx_enrollment2.coverage_termination_pending?).to be_truthy
    end

    it "has the families with hbx_enrollments and termination submitted on" do
      expect(hbx_enrollment1.termination_submitted_on.to_date).to eq Date.yesterday
      expect(hbx_enrollment2.termination_submitted_on.to_date).to eq Date.yesterday
    end
  end

  shared_examples_for "returns csv file list with terminated hbx_enrollments" do |field_name, result|
    before :each do
      subject.migrate
    end
    it "returns correct #{field_name} in csv file" do
      file = "#{Rails.root}/hbx_report/edi_enrollment_termination_report.csv"
      CSV.foreach(file, :headers => true).with_index do |csv_obj, i|
        expect(csv_obj[field_name]).to eq result if i!=0
      end
    end
  end

  it_behaves_like "returns csv file list with terminated hbx_enrollments", 'Enrolled_Member_First_Name', "F_name1"
  it_behaves_like "returns csv file list with terminated hbx_enrollments", 'Enrolled_Member_Last_Name', "L_name1"
  it_behaves_like "returns csv file list with terminated hbx_enrollments", 'Employee_Census_State', "IVL"
  it_behaves_like "returns csv file list with terminated hbx_enrollments", 'Coverage_Type', "health"
  it_behaves_like "returns csv file list with terminated hbx_enrollments", 'Enrollment_State', "coverage_terminated"
  it_behaves_like "returns csv file list with terminated hbx_enrollments", 'Market_Kind', "employer_sponsored"
end