require 'rails_helper'
require 'aasm/rspec'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
describe LawfulPresenceDetermination do

  after :each do
    DatabaseCleaner.clean
  end

  let(:consumer_role) {
    FactoryBot.create(:consumer_role_object)
  }
  let(:person_id) { consumer_role.person.id }
  let(:payload) { "lsjdfioennnklsjdfe" }

  describe "in a verification pending state with no responses" do
    it "returns nil for latest response date" do
      found_person = Person.find(person_id)
      lawful_presence_determination = found_person.consumer_role.lawful_presence_determination
      expect(lawful_presence_determination.latest_denial_date).not_to be_truthy
    end
  end

  describe "being given an ssa response which fails" do
    before :each do
      consumer_role.coverage_purchased!
    end
    it "should have the ssa response document" do
      consumer_role.lawful_presence_determination.ssa_responses << EventResponse.new({received_at: Time.now, body: payload})
      consumer_role.person.save!
      found_person = Person.find(person_id)
      ssa_response = found_person.consumer_role.lawful_presence_determination.ssa_responses.first
      expect(ssa_response.body).to eq payload
    end

    it "returns the latest received response date" do
      args = OpenStruct.new
      args.determined_at = TimeKeeper.datetime_of_record - 1.month
      args.vlp_authority = "dhs"
      consumer_role.lawful_presence_determination.ssa_responses << EventResponse.new({received_at: args.determined_at, body: payload})
      consumer_role.ssn_invalid!(args)
      consumer_role.person.save!
      found_person = Person.find(person_id)
      lawful_presence_determination = found_person.consumer_role.lawful_presence_determination
      expect(lawful_presence_determination.latest_denial_date).to be_within(1.second).of(TimeKeeper.datetime_of_record - 1.month)
    end
  end

  describe "being given an vlp response which fails" do
    before :each do
      consumer_role.coverage_purchased!
    end
    it "should have the vlp response document" do
      consumer_role.lawful_presence_determination.vlp_responses << EventResponse.new({received_at: Time.now, body: payload})
      consumer_role.person.save!
      found_person = Person.find(person_id)
      vlp_response = found_person.consumer_role.lawful_presence_determination.vlp_responses.first
      expect(vlp_response.body).to eq payload
    end

    it "returns the latest received response date" do
      args = OpenStruct.new
      args.determined_at = TimeKeeper.datetime_of_record - 1.month
      args.vlp_authority = "dhs"
      consumer_role.lawful_presence_determination.vlp_responses << EventResponse.new({received_at: args.determined_at, body: payload})
      consumer_role.ssn_invalid!(args)
      consumer_role.person.save!
      found_person = Person.find(person_id)
      lawful_presence_determination = found_person.consumer_role.lawful_presence_determination
      expect(lawful_presence_determination.latest_denial_date).to be_within(1.second).of(TimeKeeper.datetime_of_record - 1.month)
    end
  end
end

describe LawfulPresenceDetermination do
  let(:person) { Person.new }
  let(:requested_start_date) { double }
  describe "given a citizen status of us_citizen" do
    subject { LawfulPresenceDetermination.new(citizen_status: "us_citizen", :ivl_role => ConsumerRole.new(:person => person)) }

    it "should invoke the ssa workflow event when asked to begin the lawful presence process" do
      expect(subject).to receive(:notify).with(LawfulPresenceDetermination::SSA_VERIFICATION_REQUEST_EVENT_NAME, {:person => person})
      subject.start_ssa_process
    end
  end

  describe "given a citizen status of naturalized_citizen" do
    subject { LawfulPresenceDetermination.new(citizen_status: "naturalized_citizen", :ivl_role => ConsumerRole.new(:person => person)) }
    it "should invoke the vlp workflow event when asked to begin the lawful presence process" do
      expect(subject).to receive(:notify).with(LawfulPresenceDetermination::VLP_VERIFICATION_REQUEST_EVENT_NAME, {:person => person, :coverage_start_date => requested_start_date})
      subject.start_vlp_process(requested_start_date)
    end
  end
end

describe LawfulPresenceDetermination do
  context "state machine" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    subject { person.consumer_role.lawful_presence_determination }
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.now, :authority => "hbx" })}
    all_states = [:verification_pending, :verification_outstanding, :verification_successful]
    context "authorize" do
      all_states.each do |state|
        it "changes #{state} to verification_successful" do
          expect(subject).to transition_from(state).to(:verification_successful).on_event(:authorize, verification_attr)
        end
      end
    end

    context "deny" do
      all_states.each do |state|
        it "changes #{state} to verification_outstanding" do
          expect(subject).to transition_from(state).to(:verification_outstanding).on_event(:deny, verification_attr)
        end
      end
    end

    context "revert" do
      all_states.each do |state|
        it "changes #{state} to verification_pending" do
          expect(subject).to transition_from(state).to(:verification_pending).on_event(:revert, verification_attr)
        end
      end
    end
  end

  context 'qualified non citizenship code' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    subject { person.consumer_role.lawful_presence_determination }

    context 'store qnc result if present' do
      let(:verification_attr) { OpenStruct.new({ :determined_at => Time.now, :authority => 'hbx' , :qualified_non_citizenship_result => 'Y'})}

      it 'should store QNC result on authorize' do
        subject.authorize!(verification_attr)
        expect(subject.qualified_non_citizenship_result).to eq('Y')
      end

      it 'should store QNC result on deny' do
        verification_attr.qualified_non_citizenship_result = 'N'
        subject.deny!(verification_attr)
        expect(subject.qualified_non_citizenship_result).to eq('N')
      end
    end

    context 'do not store qnc result if not present' do
      let(:verification_attr) { OpenStruct.new({ :determined_at => Time.now, :authority => 'hbx' })}

      it 'should not store QNC result on authorize' do
        subject.authorize!(verification_attr)
        expect(subject.qualified_non_citizenship_result).to eq(nil)
      end

      it 'should not store QNC result on deny' do
        subject.deny!(verification_attr)
        expect(subject.qualified_non_citizenship_result).to eq(nil)
      end
    end

  end
end
end
