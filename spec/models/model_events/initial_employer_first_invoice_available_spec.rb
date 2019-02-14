require 'rails_helper'

RSpec.describe 'ModelEvents::InitialEmployerInvoiceAvailable', dbclean: :after_each do

  let(:model_event) { "initial_employer_invoice_available" }
  let(:notice_event) { "initial_employer_invoice_available" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let(:organization) { FactoryGirl.create(:organization) }
  let(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
  let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, aasm_state: 'enrolled') }

  describe "NoticeTrigger" do
    context "when initial invoice is generated" do
      subject { Observers::NoticeObserver.new }
      let!(:model_event) { ModelEvents::ModelEvent.new(:initial_employer_invoice_available, plan_year, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.initial_employer_invoice_available"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq plan_year.id.to_s
        end
        subject.deliver(recipient: employer_profile, event_object: plan_year, notice_event: notice_event, notice_params: {})
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.plan_year.current_py_start_date",
        "employer_profile.plan_year.binder_payment_due_date",
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
        "event_object_id" => plan_year.id
    } }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
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

      it "should return plan year start date" do
        expect(merge_model.plan_year.current_py_start_date).to eq plan_year.start_on.strftime("%m/%d/%Y")
      end

      it "should return binder payment due date start date" do
        due_date = PlanYear.calculate_open_enrollment_date(plan_year.start_on)[:binder_payment_due_date]
        expect(merge_model.plan_year.binder_payment_due_date).to eq due_date.strftime("%m/%d/%Y")
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end