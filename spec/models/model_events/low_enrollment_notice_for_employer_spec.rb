require 'rails_helper'

describe 'ModelEvents::LowEnrollmentNoticeForEmployer', dbclean: :around_each do

  let!(:person){ create :person }
  let!(:notice_event)    { "low_enrollment_notice_for_employer" }
  let!(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let!(:employer) { FactoryGirl.create(:employer_profile) }
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer, start_on: start_on, aasm_state: 'enrolling') }
  let!(:benefit_group)  { FactoryGirl.create(:benefit_group, plan_year: model_instance) }
  let!(:date_mock_object) { double("Date", day: (model_instance.open_enrollment_end_on - 2.days).day)}

  before do
    allow(TimeKeeper).to receive(:date_of_record).and_return model_instance.open_enrollment_end_on - 2.days
  end

  describe "ModelEvent" do
    context "when initial employer 2 days prior to dead line" do
      it "should trigger model event" do
        expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employer, event_object: model_instance, notice_event: notice_event).and_return(true)
        PlanYear.date_change_event(TimeKeeper.date_of_record)
      end
    end
  end

   describe "NoticeTrigger" do
    subject { Observers::NoticeObserver.new }
    let(:model_event) { ModelEvents::ModelEvent.new(:low_enrollment_notice_for_employer, model_instance, {}) }

    context '2 days prior to publishing dead line' do
      it 'should trigger notice event' do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.low_enrollment_notice_for_employer"
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.plan_year_date_change(model_event)
      end
    end

    context 'when plan year changes from renewing draft to renewing enrolling' do
      let(:start_on) { (TimeKeeper.date_of_record.beginning_of_month + 2.months).prev_year }
      let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer, start_on: start_on, :aasm_state => 'active' ) }
      let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
      let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer, start_on: start_on + 1.year, :aasm_state => 'renewing_enrolling', open_enrollment_start_on: TimeKeeper.date_of_record.prev_day) }
      let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance, title: "Benefits #{model_instance.start_on.year}") }

      it 'should trigger model event' do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq 'acapi.info.events.employer.low_enrollment_notice_for_employer'
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.plan_year_date_change(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        'employer_profile.notice_date',
        'employer_profile.employer_name',
        'employer_profile.plan_year.current_py_start_date',
        'employer_profile.plan_year.initial_py_publish_due_date',
        'employer_profile.plan_year.current_py_oe_end_date',
        'employer_profile.broker.primary_fullname',
        'employer_profile.broker.organization',
        'employer_profile.broker.phone',
        'employer_profile.broker.email',
        'employer_profile.broker_present?'
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "PlanYear",
        "event_object_id" => model_instance.id
    } }

    context 'when notice event received' do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient, event_name: notice_event) }

      before do
        allow(subject).to receive(:resource).and_return(employer)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it 'should return merge model' do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it 'should return the date of the notice' do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it 'should return employer name' do
        expect(merge_model.employer_name).to eq employer.legal_name
      end

      it 'should return plan year start date' do
        expect(merge_model.plan_year.current_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it 'should return publish due date' do
        expect(merge_model.plan_year.initial_py_publish_due_date).to eq Date.new(model_instance.start_on.prev_month.year, model_instance.start_on.prev_month.month, Settings.aca.shop_market.initial_application.publish_due_day_of_month).strftime('%m/%d/%Y')
      end

      it 'should return plan year open enrollment end date' do
        expect(merge_model.plan_year.current_py_oe_end_date).to eq model_instance.open_enrollment_end_on.strftime('%m/%d/%Y')
      end

      it 'should return false when there is no broker linked to employer' do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        'employer_profile.notice_date',
        'employer_profile.employer_name',
        'employer_profile.plan_year.current_py_oe_end_date',
        'employer_profile.broker.primary_fullname',
        'employer_profile.broker.organization',
        'employer_profile.broker.phone',
        'employer_profile.broker.email',
        'employer_profile.broker_present?'
      ]
    }

    let(:start_on) { (TimeKeeper.date_of_record.beginning_of_month + 2.months).prev_year }
    let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer, start_on: start_on, :aasm_state => 'active' ) }
    let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
    let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer, start_on: start_on + 1.year, :aasm_state => 'renewing_enrolling', open_enrollment_start_on: TimeKeeper.date_of_record.prev_day) }
    let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance, title: "Benefits #{model_instance.start_on.year}") }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "PlanYear",
        "event_object_id" => model_instance.id
    } }

    context 'when notice event received' do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient, event_name: notice_event) }

      before do
        allow(subject).to receive(:resource).and_return(employer)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it 'should return merge model' do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it 'should return the date of the notice' do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it 'should return employer name' do
        expect(merge_model.employer_name).to eq employer.legal_name
      end

      it 'should return plan year open enrollment end date' do
        expect(merge_model.plan_year.current_py_oe_end_date).to eq model_instance.open_enrollment_end_on.strftime('%m/%d/%Y')
      end

      it 'should return false when there is no broker linked to employer' do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end