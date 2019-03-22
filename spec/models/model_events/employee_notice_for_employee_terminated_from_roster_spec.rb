require 'rails_helper'

RSpec.describe 'ModelEvents::EmployeeNoticeForEmployeeTerminatedFromRoster', dbclean: :around_each  do

  let(:model_event)  { "employee_notice_for_employee_terminated_from_roster" }
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let(:family)  { person.primary_family }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group) }
  let!(:organization) { FactoryGirl.create(:organization) }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name, employee_role_id: employee_role.id, employment_terminated_on: TimeKeeper.date_of_record.prev_day, coverage_terminated_on: TimeKeeper.date_of_record.end_of_month) }
  let!(:model_instance) {census_employee}
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person) }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, household: family.active_household, employee_role_id: employee_role.id, aasm_state: "coverage_enrolled", benefit_group_id: benefit_group.id) }
  let!(:dental_enrollment) {FactoryGirl.create(:hbx_enrollment, :with_dental_coverage_kind, household: family.active_household, employee_role_id: employee_role.id, aasm_state: "coverage_enrolled", benefit_group_id: benefit_group.id)}

  describe "when an employer successfully terminates employee from roster" do

    let(:subject)     { Observers::NoticeObserver.new }

    context "ModelEvent" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:census_employee_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :employee_notice_for_employee_terminated_from_roster, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.terminate_employee_role!
      end
    end

    context "NoticeTrigger" do
      let(:model_event) { ModelEvents::ModelEvent.new(:employee_notice_for_employee_terminated_from_roster, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_notice_for_employee_terminated_from_roster"
          expect(payload[:event_object_kind]).to eq 'CensusEmployee'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.census_employee_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    before do
      employee_role.update_attributes(census_employee_id: census_employee.id)
      model_instance.terminate_employee_role!
    end

    context "when employee_notice_for_employee_terminated_from_roster is triggered" do
      let(:data_elements) {
        [
            "employee_profile.notice_date",
            "employee_profile.first_name",
            "employee_profile.last_name",
            "employee_profile.employer_name",
            "employee_profile.enrollment.plan_name",
            "employee_profile.dental_enrollment.plan_name",
            "employee_profile.enrollment.coverage_end_on",
            "employee_profile.enrollment.coverage_kind",
            "employee_profile.termination_of_employment",
            "employee_profile.coverage_terminated_on",
            "employee_profile.coverage_terminated_on_plus_30_days"
        ]
      }

      let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "CensusEmployee",
          "event_object_id" => model_instance.id
      } }
      let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient, event_name: 'employee_notice_for_employee_terminated_from_roster') }
      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return notice date" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq model_instance.employer_profile.legal_name
      end

      it "should return employee first_name" do
        expect(merge_model.first_name).to eq model_instance.first_name
      end

      it "should return employee last_name" do
        expect(merge_model.last_name).to eq model_instance.last_name
      end

      it 'should return health enrollment plan name' do
        expect(merge_model.enrollment.plan_name).to eq hbx_enrollment.plan.name
      end

      it 'should return dental enrollment plan name' do
        expect(merge_model.dental_enrollment.plan_name).to eq dental_enrollment.plan.name
      end

      it "should return employee termination_of_employment" do
        expect(merge_model.termination_of_employment).to eq model_instance.employment_terminated_on.strftime('%m/%d/%Y')
      end

      it "should return employee coverage_terminated_on" do
        expect(merge_model.coverage_terminated_on).to eq census_employee.coverage_terminated_on.strftime('%m/%d/%Y')
      end

      it "should return employee coverage_terminated_on plus 30 days" do
        expect(merge_model.coverage_terminated_on_plus_30_days).to eq((census_employee.coverage_terminated_on + 30.days).strftime('%m/%d/%Y'))
      end
    end
  end
end
