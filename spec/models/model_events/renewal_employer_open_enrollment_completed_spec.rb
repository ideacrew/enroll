require 'rails_helper'
include ActionView::Helpers::NumberHelper

 describe 'ModelEvents::RenewalEmployerOpenEnrollmentCompleted', dbclean: :after_each do

  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer) { FactoryGirl.create(:employer_profile) }
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer, start_on: start_on + 1.year, :aasm_state => 'renewing_enrolling' ) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance, title: "Benefits #{model_instance.start_on.year}") }
  let(:person) { FactoryGirl.create(:person, :with_family) }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer, employee_role_id: employee_role.id) }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, household: person.primary_family.active_household, employee_role_id: employee_role.id, aasm_state: "coverage_enrolled", benefit_group_id: renewal_benefit_group.id, benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer, person: person) }
  let!(:date_mock_object) { (start_on - 2.months).end_of_month.prev_day }

  describe "ModelEvent" do

    before do
      allow(model_instance).to receive(:is_enrollment_valid?).and_return true
      allow(model_instance).to receive(:is_open_enrollment_closed?).and_return true
    end

    context "when renewal employer open enrollment is completed" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :renewal_employer_open_enrollment_completed, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.advance_date!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when renewal employer OE completed" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:renewal_employer_open_enrollment_completed, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.renewal_employer_open_enrollment_completed"
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.renewal_employee_enrollment_confirmation"
          expect(payload[:employee_role_id]).to eq employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq hbx_enrollment.id.to_s
        end
        subject.plan_year_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    context "when renewal_employer_open_enrollment_completed notice event received" do

      let(:data_elements) {
        [
          "employer_profile.notice_date",
          "employer_profile.employer_name",
          "employer_profile.plan_year.renewal_py_start_date",
          "employer_profile.broker.primary_fullname",
          "employer_profile.broker.organization",
          "employer_profile.broker.phone",
          "employer_profile.broker.email",
          "employer_profile.broker_present?"
        ]
      }
      let(:merge_model) { subject.construct_notice_object }
      let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "PlanYear",
          "event_object_id" => model_instance.id
      } }

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should retrun merge mdoel" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer.legal_name
      end

      it "should return plan year start date" do
        expect(merge_model.plan_year.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end

    context "when renewal_employee_enrollment_confirmation notice event received" do

      let(:data_elements) {
        [
          "employee_profile.notice_date",
          "employee_profile.first_name",
          "employee_profile.last_name",
          "employee_profile.employer_name",
          "employee_profile.enrollment.coverage_start_on",
          "employee_profile.enrollment.employee_responsible_amount",
          "employee_profile.enrollment.employer_responsible_amount",
          "employee_profile.enrollment.plan_name"
        ]
      }
      let(:merge_model) { subject.construct_notice_object }
      let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "HbxEnrollment",
          "event_object_id" => hbx_enrollment.id
      } }

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should retrun merge mdoel" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer.legal_name
      end

      it "should return employee first name" do
        expect(merge_model.first_name).to eq person.first_name
      end

      it "should return employee last name" do
        expect(merge_model.last_name).to eq person.last_name
      end

      it "should return enrollment effective on" do
        expect(merge_model.enrollment.coverage_start_on).to eq hbx_enrollment.effective_on.strftime('%m/%d/%Y')
      end

      it "should return enrollment employer_responsible_amount" do
        expect(merge_model.enrollment.employer_responsible_amount).to eq number_to_currency(hbx_enrollment.total_employer_contribution, precision: 2)
      end

      it "should return enrollment employee_responsible_amount" do
        expect(merge_model.enrollment.employee_responsible_amount).to eq number_to_currency(hbx_enrollment.total_employee_cost, precision: 2)
      end

      it "should return enrollment plan name" do
        expect(merge_model.enrollment.plan_name).to eq hbx_enrollment.plan.name
      end
    end
  end
end
