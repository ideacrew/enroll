require 'rails_helper'

describe 'ModelEvents::InEligibleRenewalApplicationSubmittedNotification' do

  let(:model_event)  { "ineligible_renewal_application_submitted" }
  let(:notice_event) { "ineligible_renewal_application_submitted" }
  let(:start_on) { (TimeKeeper.date_of_record + 3.months).beginning_of_month }

  let!(:employer) { create(:employer_with_planyear, start_on: (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year, plan_year_state: 'active') }
  let(:model_instance) { build(:renewing_plan_year, employer_profile: employer, start_on: start_on, aasm_state: 'renewing_draft', benefit_groups: [benefit_group]) }
  let(:benefit_group) { FactoryGirl.create(:benefit_group) }

  describe "ModelEvent" do
    before :each do
     allow(employer).to receive(:is_primary_office_local?).and_return(false)
    end

    context "when In eligible renewal application created" do

      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :ineligible_renewal_application_submitted, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.publish!
      end
    end
  end

  describe "NoticeTrigger" do

    before :each do
      allow(employer).to receive(:is_primary_office_local?).and_return(false)
    end

    context "when In eligible renewal application created" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:ineligible_renewal_application_submitted, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.employer_renewal_eligibility_denial_notice"
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        subject.plan_year_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do
    let(:data_elements) {
      %w(employer_profile.employer_name employer_profile.plan_year.renewal_py_start_on
         employer_profile.plan_year.renewal_py_start_date employer_profile.broker.primary_fullname employer_profile.broker.organization
         employer_profile.broker.phone employer_profile.broker.email employer_profile.broker_present?)
     }

    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { {
        "event_object_kind" => "PlanYear",
        "event_object_id" => model_instance.id
    } }
    let(:staff_role) { double("Staff_role", first_name: "rspec", last_name: "mock" )}

    before :each do
      allow(employer).to receive(:staff_roles).and_return [staff_role]
      allow(employer).to receive(:is_primary_office_local?).and_return(false)
    end

    context "when notice event received" do
      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }
      before do
        allow(subject).to receive(:resource).and_return(employer)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.publish
        model_instance.save
      end

      it "should build the data elements for the notice" do
        merge_model = subject.construct_notice_object
        expect(merge_model).to be_a(recipient.constantize)
        expect(merge_model.first_name).to eq employer.staff_roles.first.first_name
        expect(merge_model.employer_name).to eq employer.legal_name
        expect(merge_model.plan_year.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
        expect(merge_model.broker_present?).to be_falsey
        expect(merge_model.plan_year.renewal_py_start_on).to eq model_instance.start_on
      end
    end
  end
end
