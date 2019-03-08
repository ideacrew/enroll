require 'rails_helper'

RSpec.describe 'ModelEvents::EmployerInvoiceAvailableNotice', dbclean: :after_each do

  let(:notice_event) { "employer_invoice_available_notice" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let(:organization) { FactoryGirl.create(:organization, :with_active_plan_year) }
  let(:employer_profile) { organization.employer_profile }
  let(:plan_year) { employer_profile.plan_years.first }

  let(:model_instance) {Document.new({ title: "file_name_1",
    date: TimeKeeper.date_of_record,
    creator: "hbx_staff",
    subject: "invoice",
    identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:#bucket_name#key",
    format: "file_content_type"
  })}

  describe "NoticeTrigger" do
    context "when non-first month invoice is generated" do
      subject { Services::NoticeService.new }

      before do
        allow(model_instance).to receive(:documentable).and_return(organization.employer_profile)
      end

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.employer_invoice_available_notice"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq plan_year.id.to_s
        end
        subject.deliver(recipient: employer_profile, event_object: plan_year, notice_event: notice_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
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
        organization.documents << model_instance
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

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end