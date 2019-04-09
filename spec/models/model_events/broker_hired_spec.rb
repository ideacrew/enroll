require 'rails_helper'

RSpec.describe 'ModelEvents::BrokerHired', dbclean: :around_each  do

  let(:start_on)                { TimeKeeper.date_of_record}
  let!(:person)                 { FactoryGirl.create :person }
  let!(:employer_profile)       { FactoryGirl.create(:employer_profile) }

  let!(:broker_agency)          { FactoryGirl.create(:broker_agency) }
  let!(:broker_agency_profile)  { broker_agency.broker_agency_profile }

  let(:person1)                 { FactoryGirl.create(:person) }
  let(:model_instance)          { employer_profile.broker_agency_accounts.build(broker_agency_profile: broker_agency_profile, writing_agent_id: broker_agency_profile.primary_broker_role.id, start_on: start_on) }

  describe "when ER successfully hires a broker" do

    context "ModelEvent" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:broker_agency_account_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :broker_hired, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.save
      end
    end

    context "NoticeTrigger" do

      let(:subject)     { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:broker_hired, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.broker.broker_hired_notice_to_broker"
          expect(payload[:event_object_kind]).to eq 'EmployerProfile'
          expect(payload[:event_object_id]).to eq employer_profile.id.to_s
        end
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.broker_hired_confirmation_to_employer"
          expect(payload[:event_object_kind]).to eq 'EmployerProfile'
          expect(payload[:event_object_id]).to eq employer_profile.id.to_s
        end
        subject.broker_agency_account_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    before do
      broker_agency_profile.primary_broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id)
      model_instance.save
    end

    let(:broker_role) { broker_agency_profile.primary_broker_role }
    let!(:employer_staff_role) { FactoryGirl.create(:employer_staff_role, person: person, employer_profile_id: employer_profile.id) }

    context "when broker_hired_notice_to_broker is triggered" do
      let(:data_elements) {
        [
            "broker_profile.notice_date",
            "broker_profile.employer_name",
            "broker_profile.first_name",
            "broker_profile.last_name",
            "broker_profile.assignment_date",
            "broker_profile.broker_agency_name",
            "broker_profile.employer_poc_firstname",
            "broker_profile.employer_poc_lastname"
        ]
      }

      let(:recipient) { "Notifier::MergeDataModels::BrokerProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "EmployerProfile",
          "event_object_id" => employer_profile.id
      } }
      let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(broker_agency_profile.primary_broker_role)
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

      it "should return broker first name " do
        expect(merge_model.first_name).to eq broker_role.person.first_name
      end

      it "should return broker last name " do
        expect(merge_model.last_name).to eq broker_role.person.last_name
      end

      it "should return broker assignment date" do
        expect(merge_model.assignment_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return employer poc first name" do
        expect(merge_model.employer_poc_firstname).to eq employer_profile.staff_roles.first.first_name
      end

      it "should return employer poc last name" do
        expect(merge_model.employer_poc_lastname).to eq employer_profile.staff_roles.first.last_name
      end

      it "should return broker agency name " do
        expect(merge_model.broker_agency_name).to eq broker_agency_profile.legal_name
      end
    end

    context "when broker_agency_hired_confirmation is triggered" do
      let(:data_elements) {
        [
          "employer_profile.notice_date",
          "employer_profile.employer_name",
          "employer_profile.broker.primary_first_name",
          "employer_profile.broker.primary_last_name",
          "employer_profile.broker.assignment_date",
          "employer_profile.broker.primary_first_name",
          "employer_profile.broker.organization"
        ]
      }
      let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "EmployerProfile",
          "event_object_id" => employer_profile.id
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

      it "should return broker first name" do
        expect(merge_model.broker.primary_first_name).to eq model_instance.writing_agent.parent.first_name
      end

      it "should return broker last name " do
        expect(merge_model.broker.primary_last_name).to eq model_instance.writing_agent.parent.last_name
      end

      it "should return broker assignment date" do
        expect(merge_model.broker.assignment_date).to eq model_instance.start_on.strftime("%m/%d/%Y")
      end

      it "should return broker agency name " do
        expect(merge_model.broker.organization).to eq broker_agency_profile.legal_name
      end
    end
  end
end
