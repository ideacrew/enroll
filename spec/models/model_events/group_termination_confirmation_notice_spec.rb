require 'rails_helper'

describe 'ModelEvents::GroupTerminationConfirmationNotice', dbclean: :around_each do
  let(:person) { FactoryGirl.create(:person, :with_family) }
  let(:family)  { person.primary_family }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, aasm_state: 'active') }
  let!(:benefit_group)  { FactoryGirl.create(:benefit_group, plan_year: model_instance) }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, employee_role_id: employee_role.id) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person) }
  let!(:end_on) {TimeKeeper.date_of_record.end_of_month}
  let(:termination_kind) {"nonpayment"}
   
  describe "ModelEvent" do
    context "when group is terminated" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :group_termination_confirmation_notice, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.terminate!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when group terminated due to nonpayment" do
      subject { Observers::NoticeObserver.new }

       let(:model_event) { ModelEvents::ModelEvent.new(:group_termination_confirmation_notice, model_instance, {}) }

       it "should trigger notice event" do
        allow(model_instance).to receive(:termination_kind).and_return(termination_kind)

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.notify_employer_of_group_non_payment_termination"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.notify_employee_of_group_non_payment_termination"
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.plan_year_update(model_event)
      end
    end

    context "when group terminated for voluntary reason" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:group_termination_confirmation_notice, model_instance, {}) }

      it "should trigger notice event" do
        allow(model_instance).to receive(:termination_kind).and_return(nil)

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.group_advance_termination_confirmation"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.notify_employee_of_group_advance_termination"
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject.notifier).not_to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employer_notice_for_employee_coverage_termination"
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject.notifier).not_to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_notice_for_employee_coverage_termination"
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.plan_year_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    context 'when notice for employer is received' do

      let(:data_elements) {
        [
          'employer_profile.notice_date',
          'employer_profile.employer_name',
          'employer_profile.plan_year.current_py_end_date',
          'employer_profile.plan_year.group_termination_plus_31_days',
          'employer_profile.broker.primary_fullname',
          'employer_profile.broker.organization',
          'employer_profile.broker.phone',
          'employer_profile.broker_present?'
        ]
      }
      let(:merge_model) { subject.construct_notice_object }
      let(:recipient) { 'Notifier::MergeDataModels::EmployerProfile' }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          'event_object_kind' => 'PlanYear',
          'event_object_id' => model_instance.id
      } }

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.terminate!
        allow(model_instance).to receive(:end_on).and_return(end_on)
      end

      it 'should return merge model' do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it 'should return the date of the notice' do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it 'should return employer name' do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it 'should return plan year end date' do
        expect(merge_model.plan_year.current_py_end_date).to eq model_instance.end_on.strftime('%m/%d/%Y')
      end

      it 'should return plan year group termination date plus 31 calender days' do
        expect(merge_model.plan_year.group_termination_plus_31_days).to eq (model_instance.end_on + 31.days).strftime('%m/%d/%Y')
      end


      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end

    context 'when notice for employee is received' do
      let(:data_elements) {
        [
          'employee_profile.notice_date',
          'employee_profile.employer_name',
          'employee_profile.plan_year.current_py_end_date',
          'employee_profile.plan_year.current_py_plus_60_days',
          'employee_profile.plan_year.group_termination_plus_31_days',
          'employee_profile.broker.primary_fullname',
          'employee_profile.broker.organization',
          'employee_profile.broker.phone',
          'employee_profile.broker_present?'
        ]
      }
      let(:merge_model) { subject.construct_notice_object }
      let(:recipient) { 'Notifier::MergeDataModels::EmployeeProfile' }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          'event_object_kind' => 'PlanYear',
          'event_object_id' => model_instance.id
      } }

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.terminate!
        allow(model_instance).to receive(:end_on).and_return(end_on)
      end

      it 'should return merge model' do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it 'should return the date of the notice' do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it 'should return employer name' do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it 'should return plan year end date' do
        expect(merge_model.plan_year.current_py_end_date).to eq model_instance.end_on.strftime('%m/%d/%Y')
      end

      it 'should return plan year end date plus 60 days' do
        expect(merge_model.plan_year.current_py_plus_60_days).to eq (model_instance.end_on + 60.days).strftime('%m/%d/%Y')
      end

      it 'should return plan year group termination date plus 31 calender days' do
        expect(merge_model.plan_year.group_termination_plus_31_days).to eq (model_instance.end_on + 31.days).strftime('%m/%d/%Y')
      end

      it 'should return false when there is no broker linked to employer' do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end