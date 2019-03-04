require 'rails_helper'

 currency = ActionView::Base.new
 currency.extend ActionView::Helpers::NumberHelper

 describe 'ModelEvents::InitialEmployeePlanSelectionConfirmation', dbclean: :around_each do

  let(:model_event)  { "initial_employee_plan_selection_confirmation" }
  let(:notice_event) { "initial_employee_oe_end_reminder_notice" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:organization) { FactoryGirl.create(:organization) }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization, aasm_state: "eligible") }
  let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, aasm_state: 'enrolled') }
  let(:person){ FactoryGirl.create(:person, :with_family)}
  let(:family) { person.primary_family}
  let!(:model_instance) {census_employee}
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, employee_role_id: employee_role.id) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person) }
  let(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year)}
  let(:benefit_group_assignment)    { FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee, start_on: start_on, benefit_group_id: benefit_group.id, hbx_enrollment_id: hbx_enrollment.id ) }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members,
    household: family.active_household,
    employee_role_id: employee_role.id, 
    aasm_state: "shopping",
    benefit_group_id: benefit_group.id,
    effective_on: start_on
  )}


   before do
    allow(census_employee).to receive_message_chain("active_benefit_group_assignment.hbx_enrollment").and_return(hbx_enrollment)
    benefit_group_assignment.update_attributes(hbx_enrollment_id: hbx_enrollment.id)
  end

  describe "Plan selection confirmation when ER made binder payment" do
    context "ModelEvent" do
      it "should set to true after transition" do
        employer_profile.observer_peers.keys.each do |observer|
          expect(observer).to receive(:employer_profile_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :initial_employee_plan_selection_confirmation, :klass_instance => employer_profile, :options => {})
          end
        end
        employer_profile.binder_credited!
      end
    end

    context "NoticeTrigger" do
      subject {Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:initial_employee_plan_selection_confirmation, employer_profile, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.initial_employee_plan_selection_confirmation"
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq hbx_enrollment.id.to_s
        end
        subject.employer_profile_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.first_name",
        "employee_profile.last_name",
        "employee_profile.enrollment_coverage_start_on",
        "employee_profile.enrollment_plan_name",
        "employee_profile.enrollment_employer_responsible_amount",  
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?"
      ]
    }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "HbxEnrollment",
        "event_object_id" => hbx_enrollment.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employee_role)
      allow(subject).to receive(:payload).and_return(payload)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice_date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employee plan name" do
      expect(merge_model.enrollment.plan_name).to eq hbx_enrollment.plan.name
    end

    it "should return employee coverage start date" do
      expect(merge_model.enrollment.coverage_start_on).to eq hbx_enrollment.effective_on.strftime('%m/%d/%Y')
    end

    it "should return employer responsible amount" do
      expect(merge_model.enrollment.employer_responsible_amount).to eq currency.number_to_currency(hbx_enrollment.total_employer_contribution)
    end

    it "should return employee first name" do
      expect(merge_model.first_name).to eq person.first_name
    end

     it "should return employee last name" do
      expect(merge_model.last_name).to eq person.last_name
    end

    it "should return false when there is no broker linked to employer" do
      expect(merge_model.broker_present?).to be_falsey
    end
  end
end