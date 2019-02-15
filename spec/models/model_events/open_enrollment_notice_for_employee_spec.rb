require 'rails_helper'

RSpec.describe 'ModelEvents::OpenEnrollmentNoticeForEmployee', dbclean: :after_each do

  let(:auto_renewal_notice_event) { 'employee_open_enrollment_auto_renewal' }
  let(:unenrolled_notice_event) { 'employee_open_enrollment_unenrolled' }
  let(:no_renewal_notice_event) { 'employee_open_enrollment_no_auto_renewal' }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ FactoryGirl.create(:person, :with_family)}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:active_benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
  let!(:renewal_benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: renewal_benefit_group, census_employee: census_employee) }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }

  def renew_ce
    factory = Factories::FamilyEnrollmentRenewalFactory.new
    factory.family = person.primary_family
    factory.census_employee = census_employee
    factory.employer = employer_profile
    factory.renewing_plan_year = renewal_plan_year
    factory.renew
  end

  before do
    census_employee.update_attributes!(employee_role_id: employee_role.id)
  end

  describe "ModelEvent" do

    context "when census_employee is enrolled" do
      before do
        hbx_enrollment.plan.update_attributes!(renewal_plan_id: renewal_benefit_group.elected_plan_ids.first)
      end

      let!(:hbx_enrollment) {
        FactoryGirl.create(:hbx_enrollment,
        household: person.primary_family.active_household,
        coverage_kind: "health",
        effective_on: active_benefit_group.start_on,
        enrollment_kind: 'open_enrollment',
        kind: "employer_sponsored",
        benefit_group_id: active_benefit_group.id,
        employee_role_id: employee_role.id,
        benefit_group_assignment_id: active_benefit_group_assignment.id,
        plan_id: active_benefit_group.reference_plan.id,
        aasm_state: 'coverage_selected',
        )
      }

      it "should trigger model event" do
        expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employee_role, event_object: renewal_plan_year, notice_event: auto_renewal_notice_event, notice_params: {}).and_return(true)
        renew_ce
      end
    end

    context "when census_employee is unenrolled" do

      it "should trigger model event" do
        expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employee_role, event_object: renewal_plan_year, notice_event: unenrolled_notice_event, notice_params: {}).and_return(true)
        renew_ce
      end
    end

    context "when census_employee has a waiver" do

      let!(:hbx_enrollment) {
        FactoryGirl.create(:hbx_enrollment,
        household: person.primary_family.active_household,
        coverage_kind: "health",
        effective_on: active_benefit_group.start_on,
        enrollment_kind: 'open_enrollment',
        kind: "employer_sponsored",
        benefit_group_id: active_benefit_group.id,
        employee_role_id: employee_role.id,
        benefit_group_assignment_id: active_benefit_group_assignment.id,
        plan_id: active_benefit_group.reference_plan.id,
        aasm_state: 'inactive',
        )
      }

      it "should trigger model event" do
        expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employee_role, event_object: renewal_plan_year, notice_event: unenrolled_notice_event, notice_params: {}).and_return(true)
        renew_ce
      end
    end

    context "when census_employee is enrolled and employer offerings has changed" do

      let!(:hbx_enrollment) {
        FactoryGirl.create(:hbx_enrollment,
        household: person.primary_family.active_household,
        coverage_kind: "health",
        effective_on: active_benefit_group.start_on,
        enrollment_kind: 'open_enrollment',
        kind: "employer_sponsored",
        benefit_group_id: active_benefit_group.id,
        employee_role_id: employee_role.id,
        benefit_group_assignment_id: active_benefit_group_assignment.id,
        plan_id: active_benefit_group.reference_plan.id,
        aasm_state: 'coverage_selected',
        )
      }

      it "should trigger model event" do
        expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employee_role, event_object: renewal_plan_year, notice_event: no_renewal_notice_event, notice_params: {}).and_return(true)
        renew_ce
      end
    end
  end

  describe "NoticeTrigger" do
    ["employee_open_enrollment_unenrolled",
      "employee_open_enrollment_auto_renewal",
      "employee_open_enrollment_no_auto_renewal"].each do |event|
      context "when employer open enrollment begins" do
        subject { Observers::NoticeObserver.new}
        let(:model_event) { ModelEvents::ModelEvent.new(event.to_sym, census_employee, {}) }

        it "should trigger notice event" do
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employee.#{event}"
            expect(payload[:employee_role_id]).to eq employee_role.id.to_s
            expect(payload[:event_object_kind]).to eq 'PlanYear'
            expect(payload[:event_object_id]).to eq renewal_plan_year.id.to_s
          end
          subject.deliver(recipient: employee_role, event_object: renewal_plan_year, notice_event: event, notice_params: {})
        end
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.plan_year.renewal_py_start_date",
        "employee_profile.plan_year.renewal_py_oe_start_date",
        "employee_profile.plan_year.renewal_py_oe_end_date",
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?"
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { {
        "event_object_kind" => 'PlanYear',
        "event_object_id" => renewal_plan_year.id
    } }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should retrun merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it "should return renewal plan year start date" do
        expect(merge_model.plan_year.renewal_py_start_date).to eq renewal_plan_year.start_on.strftime('%m/%d/%Y')
      end

      it "should return renewal plan year open enrollment start date" do
        expect(merge_model.plan_year.renewal_py_oe_start_date).to eq renewal_plan_year.open_enrollment_start_on.strftime('%m/%d/%Y')
      end

      it "should return renewal plan year open enrollment end date" do
        expect(merge_model.plan_year.renewal_py_oe_end_date).to eq renewal_plan_year.open_enrollment_end_on.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end