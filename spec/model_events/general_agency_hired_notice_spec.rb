require 'rails_helper'

RSpec.describe 'ModelEvents::GeneralAgencyHiredNotice', dbclean: :around_each  do

  let(:start_on) { TimeKeeper.date_of_record }
  let!(:person) { create :person }
  let!(:employer_profile)    { FactoryGirl.create(:employer_profile) }

  let!(:broker_agency)          { FactoryGirl.create(:broker_agency) }
  let!(:broker_agency_profile)  { broker_agency.broker_agency_profile }

  let!(:broker_agency_old)          { FactoryGirl.create(:broker_agency) }
  let!(:broker_agency_profile_old)  { broker_agency_old.broker_agency_profile }


  let!(:person1) { FactoryGirl.create(:person) }
  let!(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  let!(:broker_agency_account) { FactoryGirl.create(:broker_agency_account, employer_profile: employer_profile, broker_agency_profile_id: broker_agency_profile.id) }
  let(:broker_model_instance)          { broker_agency_profile }

  let(:ga_model_instance) { employer_profile.general_agency_accounts.build(general_agency_profile: general_agency_profile, start_on: start_on, broker_role_id: broker_agency_profile.primary_broker_role.id) }

  describe "when a GA is hired" do

    context "ModelEvent" do

      context "employer hires a broker and broker has default GA assigned" do

        before do
          broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
        end

        it "should trigger notice" do
          ga_model_instance.observer_peers.keys.each do |observer|
            expect(observer).to receive(:general_agency_account_update) do |model_event|
              expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :general_agency_hired, :klass_instance => ga_model_instance, :options => {})
            end
          end
          ga_model_instance.save
        end
      end

      context "employer changes broker and broker has default GA assigned" do

        before do
          broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
        end

        let!(:broker_agency_account_old) { FactoryGirl.create(:broker_agency_account, employer_profile: employer_profile, broker_agency_profile_id: broker_agency_profile_old.id) }
        let(:model_instance)  { employer_profile.general_agency_accounts.build(general_agency_profile: general_agency_profile, start_on: start_on, broker_role_id: broker_agency_profile.primary_broker_role.id) }

        it "should trigger notice" do
          model_instance.observer_peers.keys.each do |observer|
            expect(observer).to receive(:general_agency_account_update) do |model_event|
              expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :general_agency_hired, :klass_instance => model_instance, :options => {})
            end
          end
          model_instance.save
        end
      end

      context "broker selects a default GA and broker has clients(employers)" do

        def update_broker_agency_profile
          broker_agency_profile.default_general_agency_profile = general_agency_profile
          broker_agency_profile.save
        end

        it "should trigger notice" do
          broker_agency_profile.observer_peers.keys.each do |observer|
            expect(observer).to receive(:broker_agency_profile_update) do |model_event|
              expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :general_agency_hired, :klass_instance => broker_agency_profile, :options => {})
            end
          end
          update_broker_agency_profile
        end
      end

      context "broker assigns GA to an employer" do

        let(:model_instance)  { employer_profile.general_agency_accounts.build(general_agency_profile: general_agency_profile, start_on: start_on, broker_role_id: broker_agency_profile.primary_broker_role.id) }

        it "should trigger notice" do
          model_instance.observer_peers.keys.each do |observer|
            expect(observer).to receive(:general_agency_account_update) do |model_event|
              expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :general_agency_hired, :klass_instance => model_instance, :options => {})
            end
          end
          model_instance.save
        end
      end
    end

    context "NoticeTrigger" do

      context 'when general agency account is the event object' do
        let(:subject)     { Observers::NoticeObserver.new }
        let(:model_event) { ModelEvents::ModelEvent.new(:general_agency_hired, ga_model_instance, {}) }

        it "should trigger notice event" do
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.general_agency.general_agency_hired_confirmation_to_agency"
            expect(payload[:event_object_kind]).to eq 'EmployerProfile'
            expect(payload[:event_object_id]).to eq employer_profile.id.to_s
          end
          subject.general_agency_account_update(model_event)
        end
      end

      context 'when broker_agency_profile is the event object' do

        before do
          broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
        end

        let(:subject)     { Observers::NoticeObserver.new }
        let(:model_event) { ModelEvents::ModelEvent.new(:general_agency_hired, broker_model_instance, {}) }

        it "should trigger notice event" do
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.general_agency.general_agency_hired_confirmation_to_agency"
            expect(payload[:event_object_kind]).to eq 'EmployerProfile'
            expect(payload[:event_object_id]).to eq employer_profile.id.to_s
          end
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.general_agency.default_ga_hired_notice_to_general_agency"
            expect(payload[:event_object_kind]).to eq 'BrokerAgencyProfile'
            expect(payload[:event_object_id]).to eq broker_agency_profile.id.to_s
          end
          subject.broker_agency_profile_update(model_event)
        end
      end
    end
  end

  describe "NoticeBuilder" do

    before do
      broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
      broker_agency_profile.primary_broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id)
      ga_model_instance.save
    end

    let(:broker_role) { broker_agency_profile.primary_broker_role }
    let!(:employer_staff_role) { FactoryGirl.create(:employer_staff_role, person: person, employer_profile_id: employer_profile.id) }
    let(:data_elements) {
        [
            "general_agency.notice_date",
            "general_agency.employer_name",
            "general_agency.first_name",
            "general_agency.last_name",
            "general_agency.assignment_date",
            "general_agency.termination_date",
            "general_agency.legal_name",
            "general_agency.broker.primary_first_name",
            "general_agency.broker.primary_last_name",
            "general_agency.employer_poc_firstname",
            "general_agency.employer_poc_lastname"
        ]
      }

    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::GeneralAgency" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    context "when event is triggered with general_agency_account update" do

      let(:payload)   {
        {
          "event_object_kind" => "EmployerProfile",
          "event_object_id" => employer_profile.id.to_s,
          "notice_params" => { "general_agency_account_id" => ga_model_instance.id.to_s }
        }
      }

      before do
        allow(subject).to receive(:resource).and_return(general_agency_profile)
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

      it "should return general agency legal name" do
        expect(merge_model.legal_name).to eq general_agency_profile.legal_name
      end

      it "should return general agency - employer assignment date" do
        expect(merge_model.assignment_date).to eq start_on.strftime('%m/%d/%Y')
      end

      it "should return general agency - employer termination date" do
        expect(merge_model.termination_date).to eq start_on.strftime('%m/%d/%Y')
      end

      it "should return employer poc first name" do
        expect(merge_model.employer_poc_firstname).to eq employer_staff_role.person.first_name
      end

       it "should return employer poc last name" do
        expect(merge_model.employer_poc_lastname).to eq employer_staff_role.person.last_name
      end

      it "should return broker first name " do
        expect(merge_model.broker.primary_first_name).to eq broker_role.person.first_name
      end

      it "should return broker last name " do
        expect(merge_model.broker.primary_last_name).to eq broker_role.person.last_name
      end
    end

    context "when event is triggered with broker_agency_profile update" do

      let(:payload)   {
        {
          "event_object_kind" => "EmployerProfile",
          "event_object_id" => employer_profile.id.to_s,
          "notice_params" => { "broker_agency_profile_id" => broker_agency_profile.id.to_s }
        }
      }

      before do
        allow(subject).to receive(:resource).and_return(general_agency_profile)
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

      it "should return general agency legal name" do
        expect(merge_model.legal_name).to eq general_agency_profile.legal_name
      end

      it "should return general agency - employer assignment date" do
        expect(merge_model.assignment_date).to eq start_on.strftime('%m/%d/%Y')
      end

      it "should return general agency - employer termination date" do
        expect(merge_model.termination_date).to eq start_on.strftime('%m/%d/%Y')
      end

      it "should return employer poc first name" do
        expect(merge_model.employer_poc_firstname).to eq employer_staff_role.person.first_name
      end

       it "should return employer poc last name" do
        expect(merge_model.employer_poc_lastname).to eq employer_staff_role.person.last_name
      end

      it "should return broker first name " do
        expect(merge_model.broker.primary_first_name).to eq broker_role.person.first_name
      end

      it "should return broker last name " do
        expect(merge_model.broker.primary_last_name).to eq broker_role.person.last_name
      end
    end

    context "when event is triggered with broker_agency_profile as event_object" do

      let(:data_elements) {
        [
            "general_agency.notice_date",
            "general_agency.first_name",
            "general_agency.last_name",
            "general_agency.assignment_date",
            "general_agency.legal_name",
            "general_agency.broker.primary_first_name",
            "general_agency.broker.primary_last_name",
        ]
      }

      let(:payload)   {
        {
          "event_object_kind" => "BrokerAgencyProfile",
          "event_object_id" => broker_agency_profile.id.to_s
        }
      }

      before do
        allow(subject).to receive(:resource).and_return(general_agency_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return notice date" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return general agency legal name" do
        expect(merge_model.legal_name).to eq general_agency_profile.legal_name
      end

      it "should return general agency - broker assignment date" do
        expect(merge_model.assignment_date).to eq start_on.strftime('%m/%d/%Y')
      end

      it "should return broker first name " do
        expect(merge_model.broker.primary_first_name).to eq broker_role.person.first_name
      end

      it "should return broker last name " do
        expect(merge_model.broker.primary_last_name).to eq broker_role.person.last_name
      end
    end
  end
end