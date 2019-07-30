require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "send_employee_plan_selection_confirmation_notice")

describe SendEmployeePlanSelectionConfirmationNotice, dbclean: :after_each do

  let(:given_task_name) { "send_employee_plan_selection_confirmation_notice" }

  subject { SendEmployeePlanSelectionConfirmationNotice.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "send employee plan selection confirmation notice" do
    let!(:person) { FactoryGirl.create(:person, hbx_id: '238474') }
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile, benefit_group_id: active_benefit_group.id)}
    let!(:census_employee) { FactoryGirl.create(:census_employee, aasm_state: "eligible", employee_role_id: employee_role.id) }
    let(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile, :aasm_state => 'active')}
    let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
    let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.households.first, kind: "employer_sponsored", aasm_state: "coverage_selected", benefit_group_assignment_id: benefit_group_assignment.id) }
    let!(:hbx_enrollment_member1){ FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family.family_members[0].id, eligibility_date: TimeKeeper.date_of_record - 1.month) }
    let!(:observer) { Observers::NoticeObserver.new }
    
    before do
      allow(ENV).to receive(:[]).with("ce_id").and_return(census_employee.id)
    end

    it "should trigger plan selection confirmation notice" do
      recipient = census_employee.employee_role
      object = census_employee.active_benefit_group_assignment.hbx_enrollment
      event = 'initial_employee_plan_selection_confirmation'
      expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: recipient, event_object: object, notice_event: event)
      subject.migrate
    end
  end
end