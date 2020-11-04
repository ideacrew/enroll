require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe 'BenefitSponsors::ModelEvents::LowEnrollmentNoticeForEmployer', dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"
  let(:notice_event) { "low_enrollment_notice_for_employer" }
  let(:start_on) { Date.today.next_month.beginning_of_month}
  let(:aasm_state) { :enrollment_open }
  let(:open_enrollment_period) {start_on.prev_month..Date.new(start_on.prev_month.year, start_on.prev_month.month, Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on)}
  let(:date_mock_object) { initial_application.open_enrollment_period.max - 2.days }

  before do
    allow(TimeKeeper).to receive(:date_of_record).and_return initial_application.open_enrollment_period.max - 2.days
  end

  describe "ModelEvent" do
    it "should trigger model event" do
      initial_application.class.observer_peers.keys.each do |observer|
        expect(observer).to receive(:notifications_send) do |instance, model_event|
          expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => :low_enrollment_notice_for_employer, :klass_instance => initial_application, :options => {})
        end
      end
      BenefitSponsors::BenefitApplications::BenefitApplication.date_change_event(date_mock_object)
    end
  end

  describe "NoticeTrigger" do
    context "2 days prior to publishing dead line" do
      subject { BenefitSponsors::Observers::BenefitApplicationObserver.new }

      let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(:low_enrollment_notice_for_employer, initial_application, {}) }
      it "should trigger notice event" do
        if initial_application.effective_period.min.yday != 1
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employer.low_enrollment_notice_for_employer"
            expect(payload[:employer_id]).to eq abc_profile.hbx_id.to_s
            expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
            expect(payload[:event_object_id]).to eq initial_application.id.to_s
          end
        end
        subject.notifications_send(initial_application, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.benefit_application.current_py_start_date",
        "employer_profile.benefit_application.current_py_oe_end_date",
        "employer_profile.benefit_application.binder_payment_due_date",
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

    let(:payload) {{ "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
                     "event_object_id" => initial_application.id }}

    context "when notice event received for initial employer" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient, event_name: notice_event) }

      before do
        allow(subject).to receive(:resource).and_return(abc_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should retrun merge mdoel" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq abc_profile.legal_name
      end

      it "should return plan year start date" do
        expect(merge_model.benefit_application.current_py_start_date).to eq initial_application.start_on.strftime('%m/%d/%Y')
      end

      it 'should return plan year open enrollment end date' do
        expect(merge_model.benefit_application.current_py_oe_end_date).to eq initial_application.open_enrollment_period.max.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end

  describe "NoticeBuilder" do
    context "when notice event received for renewal employer" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup renewal application"

      let(:data_elements) do
        [
          "employer_profile.notice_date",
          "employer_profile.employer_name",
          "employer_profile.benefit_application.current_py_start_date",
          "employer_profile.benefit_application.current_py_oe_end_date",
          "employer_profile.benefit_application.binder_payment_due_date",
          "employer_profile.broker.primary_fullname",
          "employer_profile.broker.organization",
          "employer_profile.broker.phone",
          "employer_profile.broker.email",
          "employer_profile.broker_present?"
        ]
      end

      let(:merge_model) { subject.construct_notice_object }
      let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:aasm_state) { :active }
      let(:renewal_state) {:enrollment_open }
      let(:predecessor_application) { initial_application }
      let(:payload) {{ "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
                       "event_object_id" => renewal_application.id }}

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient, event_name: notice_event) }

      before do
        allow(subject).to receive(:resource).and_return(abc_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq abc_profile.legal_name
      end

      it 'should return plan year open enrollment end date' do
        expect(merge_model.benefit_application.current_py_oe_end_date).to eq renewal_application.open_enrollment_period.max.strftime('%m/%d/%Y')
      end

      it "should return binder payment due date" do
        schedular = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
        expect(merge_model.benefit_application.binder_payment_due_date).to eq schedular.map_binder_payment_due_date_by_start_on(renewal_application.start_on).strftime('%m/%d/%Y')
      end
    end
  end
end