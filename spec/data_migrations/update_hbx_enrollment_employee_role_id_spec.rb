require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_hbx_enrollment_employee_role_id")

describe UpdateHbxEnrollmentEmployeeRoleId do

  let(:given_task_name) { "update_hbx_enrollment_employee_role_id" }
  subject { UpdateHbxEnrollmentEmployeeRoleId.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update hbx_enrollment employee role id" do

    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  
    let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
    let!(:person){ create :person}
    let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
    let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
    let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: TimeKeeper.date_of_record.beginning_of_year, :aasm_state => 'published' ) }
    let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, is_congress: false, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
    let(:benefit_group_assignment1)  { FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee) }
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, :benefit_group_assignment => benefit_group_assignment1)}

    let(:hbx_enrollment) do
      hbx = FactoryGirl.create(:hbx_enrollment, household: family.active_household, kind: "employer_sponsored",employee_role_id:employee_role.id ,)
      hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record - 30.days)
      hbx.benefit_group_assignment = benefit_group_assignment1
      hbx.save
      hbx
    end
    let(:family_member) { FactoryGirl.create(:family_member, family: family)} 

    let!(:employer_profile1){ create :employer_profile, aasm_state: "active"}
    let!(:person1){ create :person}
    let(:employee_role1) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile1)}
    let(:census_employee1) { FactoryGirl.create(:census_employee, employee_role_id: employee_role1.id, employer_profile_id: employer_profile1.id) }
    let!(:plan_year1) { FactoryGirl.create(:plan_year, employer_profile: employer_profile1, start_on: TimeKeeper.date_of_record.beginning_of_year, :aasm_state => 'published' ) }
    let!(:active_benefit_group1) { FactoryGirl.create(:benefit_group, is_congress: false, plan_year: plan_year1, title: "Benefits #{plan_year1.start_on.year}") }
    let(:benefit_group_assignment2)  { FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee1) }
    
    before(:each) do
      allow(ENV).to receive(:[]).with("enrollment_hbx_id").and_return(hbx_enrollment.hbx_id.to_s)
      allow(ENV).to receive(:[]).with("employee_role_id").and_return(employee_role1.id)
    end

    context "change employee role id", dbclean: :after_each do
      it "should activate_related_benefit_group_assignment" do
        expect(hbx_enrollment.employee_role_id).to eq employee_role.id
        subject.migrate
        hbx_enrollment.reload
        hbx_enrollment.benefit_group_assignment.reload
        expect(hbx_enrollment.employee_role_id).to eq employee_role1.id
      end   
    end
  end
end

