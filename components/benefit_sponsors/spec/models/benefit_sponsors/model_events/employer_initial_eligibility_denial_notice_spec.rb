require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe 'BenefitSponsors::ModelEvents::EmployerInitialEligibilityDenialNotice', dbclean: :after_each  do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:notice_event)            { "employer_initial_eligibility_denial_notice" }
  let(:aasm_state)              { :draft }
  let(:current_effective_date)  { TimeKeeper.date_of_record.beginning_of_month.prev_year }
  let(:start_on)                { (TimeKeeper.date_of_record - 2.months).beginning_of_month }
  let(:effective_period)        { start_on..start_on.next_year.prev_day }
  let(:employer_profile)        { abc_profile }
  let!(:model_instance)         { initial_application }

  before :each do
    allow(model_instance).to receive(:is_renewing?).and_return(false)
    allow(employer_profile).to receive(:is_primary_office_local?).and_return(false)
  end

  describe "when initial employer denial" do

    context "ModelEvent" do
      it "should trigger model event" do
        model_instance.class.observer_peers.keys.each do |observer|
          expect(observer).to receive(:process_application_events) do |model_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :ineligible_application_submitted, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.submit_for_review!
      end
    end

    context "NoticeTrigger" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:ineligible_application_submitted, model_instance, {}) }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.employer_initial_eligibility_denial_notice"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.process_application_events(model_instance, model_event)
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

    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { {
      "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
      "event_object_id" => model_instance.id
    } }

    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employer_profile)
      allow(subject).to receive(:payload).and_return(payload)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
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
