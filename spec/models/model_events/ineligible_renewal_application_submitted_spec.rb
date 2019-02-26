require 'rails_helper'

describe 'ModelEvents::IneligibleRenewalApplicationSubmitted', dbclean: :around_each do

  let(:open_enrollment_end_on) { TimeKeeper.date_of_record + 11.days}
  let!(:employer_profile)       { FactoryGirl.create(:employer_profile) }
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, 
    start_on: open_enrollment_end_on.next_month.beginning_of_month,
    open_enrollment_start_on: open_enrollment_end_on - 10.days,
    open_enrollment_end_on: open_enrollment_end_on,
    aasm_state: 'renewing_draft') }
  let!(:benefit_group)  { FactoryGirl.create(:benefit_group, plan_year: model_instance) }

  before do
    allow(model_instance).to receive(:application_eligibility_warnings).and_return({:primary_office_location => "primary business address not located in #{Settings.aca.state_name}"})
  end

  describe "ModelEvent" do
    context "when renewal employer application is published" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :ineligible_renewal_application_submitted, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.force_publish!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when renewal application published" do
      subject { Observers::NoticeObserver.new }

       let(:model_event) { ModelEvents::ModelEvent.new(:ineligible_renewal_application_submitted, model_instance, {}) }

       it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.employer_renewal_eligibility_denial_notice"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.plan_year_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.plan_year.warnings"
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "PlanYear",
        "event_object_id" => model_instance.id
    } }

    context "when notice event employer_renewal_eligibility_denial_notice is received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it "should return renewal plan year warnings" do
        expect(merge_model.plan_year.warnings).to eq model_instance.application_eligibility_warnings[:primary_office_location]
      end
    end
  end
end
