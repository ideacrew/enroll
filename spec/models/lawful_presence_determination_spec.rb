require 'rails_helper'
require 'aasm/rspec'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
describe LawfulPresenceDetermination do

  after :each do
    DatabaseCleaner.clean
  end

  let(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:consumer_role) { person.consumer_role}
  let(:person_id) { person.id }
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
      consumer_role.coverage_purchased_no_residency!
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

describe '#start_ssa_process' do
  before :each do
    consumer_role.update_attributes!(aasm_state: 'verification_outstanding')
    allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:ssa_h3).and_return(true)
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_return(false)
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:check_for_crm_updates).and_return(false)
  end
  let(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:consumer_role) { person.consumer_role}
  let(:validator) { instance_double(Operations::Fdsh::EncryptedSsnValidator) }

  context 'when validate_and_record_publish_errors feature is enabled' do
    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_errors).and_return(true)
    end
    context 'when ssa_h3 feature is enabled' do
      context 'when there is no active enrollment' do
        context 'when ssa verification request is successful' do
          it 'should be pending' do
            consumer_role.lawful_presence_determination.start_ssa_process
            ssa_verification_type = consumer_role.verification_types.where(type_name: "Social Security Number").first
            expect(ssa_verification_type.validation_status).to eq('pending')
          end
        end

        context 'when ssa verification request is not successful' do
          before do
            allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
            allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
          end

          it 'should be in negative_response_received' do
            consumer_role.lawful_presence_determination.start_ssa_process
            ssa_verification_type = consumer_role.verification_types.where(type_name: "Social Security Number").first
            expect(ssa_verification_type.validation_status).to eq('negative_response_received')
          end
        end
      end

      context 'when there is an active enrollment' do
        let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
        let!(:hbx_enrollment) do
          FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_health_product,
                            family: family, enrollment_members: [family.primary_applicant],
                            aasm_state: 'coverage_selected', kind: 'individual')
        end

        context 'when ssa verification request is successful' do
          it 'should be pending' do
            consumer_role.lawful_presence_determination.start_ssa_process
            ssa_verification_type = consumer_role.verification_types.where(type_name: "Social Security Number").first
            expect(ssa_verification_type.validation_status).to eq('pending')
          end
        end

        context 'when ssa verification request is not successful' do
          before do
            allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
            allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
          end

          it 'should be in outstanding' do
            consumer_role.lawful_presence_determination.start_ssa_process
            ssa_verification_type = consumer_role.verification_types.where(type_name: "Social Security Number").first
            expect(ssa_verification_type.validation_status).to eq('outstanding')
          end
        end
      end
    end
  end

  context 'when validate_and_record_publish_errors feature is enabled' do
    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_errors).and_return(false)
    end

    context 'when ssa_h3 feature is enabled' do
      context 'when there is no active enrollment' do
        context 'when ssa verification request is successful' do
          it 'should be pending' do
            consumer_role.lawful_presence_determination.start_ssa_process
            ssa_verification_type = consumer_role.verification_types.where(type_name: "Social Security Number").first
            expect(ssa_verification_type.validation_status).to eq('pending')
          end
        end

        context 'when ssa verification request is not successful' do
          before do
            allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
            allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
          end

          it 'should be in negative_response_received' do
            consumer_role.lawful_presence_determination.start_ssa_process
            ssa_verification_type = consumer_role.verification_types.where(type_name: "Social Security Number").first
            expect(ssa_verification_type.validation_status).to eq('pending')
          end
        end
      end

      context 'when there is an active enrollment' do
        let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
        let!(:hbx_enrollment) do
          FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_health_product,
                            family: family, enrollment_members: [family.primary_applicant],
                            aasm_state: 'coverage_selected', kind: 'individual')
        end

        context 'when ssa verification request is successful' do
          it 'should be pending' do
            consumer_role.lawful_presence_determination.start_ssa_process
            ssa_verification_type = consumer_role.verification_types.where(type_name: "Social Security Number").first
            expect(ssa_verification_type.validation_status).to eq('pending')
          end
        end

        context 'when ssa verification request is not successful' do
          before do
            allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
            allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
          end

          it 'should be in outstanding' do
            consumer_role.lawful_presence_determination.start_ssa_process
            ssa_verification_type = consumer_role.verification_types.where(type_name: "Social Security Number").first
            expect(ssa_verification_type.validation_status).to eq('pending')
          end
        end
      end
    end
  end
end

describe '#start_vlp_process' do
  before :each do
    consumer_role.update_attributes!(aasm_state: 'verification_outstanding')
    allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:vlp_h92).and_return(true)
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_return(false)
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:check_for_crm_updates).and_return(false)
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_errors).and_return(true)
  end
  let(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:consumer_role) { person.consumer_role}
  let(:validator) { instance_double(Operations::Fdsh::EncryptedSsnValidator) }
  let(:requested_start_date) { double }

  context 'when vlp_h92 feature is enabled' do
    context 'when there is no active enrollment' do
      context 'when vlp verification request is successful' do
        it 'should be pending' do
          consumer_role.lawful_presence_determination.start_vlp_process(requested_start_date)
          vlp_verification_type = consumer_role.verification_types.where(type_name: "Citizenship").first
          expect(vlp_verification_type.validation_status).to eq('pending')
        end
      end

      context "when:
      - consumer_role state is in dhs_pending
      - vlp document is invalid
      - vlp verification request is not successful" do
        before do
          consumer_role.update_attributes!(aasm_state: 'dhs_pending')
          consumer_role.vlp_documents.first.update_attributes!(alien_number: nil)
          consumer_role.lawful_presence_determination.start_vlp_process(requested_start_date)
        end

        it 'changes consumer_role aasm state to verification_outstanding' do
          expect(consumer_role.aasm_state).to eq('verification_outstanding')
        end

        it 'should be in negative_response_received' do
          vlp_verification_type = consumer_role.verification_types.where(type_name: "Citizenship").first
          expect(vlp_verification_type.validation_status).to eq('negative_response_received')
        end
      end

      context "when:
        - consumer_role state is in ssa_pending
        - vlp document is invalid
        - vlp verification request is not successful" do
        before do
          consumer_role.update_attributes!(aasm_state: 'ssa_pending')
          consumer_role.vlp_documents.first.update_attributes!(alien_number: nil)
          consumer_role.lawful_presence_determination.start_vlp_process(requested_start_date)
        end

        it 'does not change consumer_role aasm state' do
          expect(consumer_role.aasm_state).to eq('ssa_pending')
        end

        it 'changes vlp_verification_type to negative_response_received' do
          vlp_verification_type = consumer_role.verification_types.where(type_name: "Citizenship").first
          expect(vlp_verification_type.validation_status).to eq('negative_response_received')
        end
      end
    end

    context 'when there is an active enrollment' do
      let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
      let!(:hbx_enrollment) do
        FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_health_product,
                          family: family, enrollment_members: [family.primary_applicant],
                          aasm_state: 'coverage_selected', kind: 'individual')
      end

      context 'when vlp verification request is successful' do
        it 'should be pending' do
          consumer_role.lawful_presence_determination.start_vlp_process(requested_start_date)
          vlp_verification_type = consumer_role.verification_types.where(type_name: "Citizenship").first
          expect(vlp_verification_type.validation_status).to eq('pending')
        end
      end

      context 'when vlp verification request is not successful' do
        before do
          allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
          allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
        end

        it 'should be in outstanding' do
          consumer_role.lawful_presence_determination.start_vlp_process(requested_start_date)
          vlp_verification_type = consumer_role.verification_types.where(type_name: "Citizenship").first
          expect(vlp_verification_type.validation_status).to eq('pending')
        end
      end
    end
  end
end

describe LawfulPresenceDetermination do
  let(:person) { Person.new }
  let(:requested_start_date) { double }
  describe "given a citizen status of us_citizen" do
    subject { LawfulPresenceDetermination.new(citizen_status: "us_citizen", :ivl_role => ConsumerRole.new(:person => person)) }

    it "should invoke the ssa workflow event when asked to begin the lawful presence process" do
      unless EnrollRegistry.feature_enabled?(:ssa_h3)
        expect(subject).to receive(:notify).with(LawfulPresenceDetermination::SSA_VERIFICATION_REQUEST_EVENT_NAME,
                                                 {:person => person})
        subject.start_ssa_process
      end
    end
  end

  describe "given a citizen status of naturalized_citizen" do
    subject { LawfulPresenceDetermination.new(citizen_status: "naturalized_citizen", :ivl_role => ConsumerRole.new(:person => person)) }
    it "should invoke the vlp workflow event when asked to begin the lawful presence process" do
      unless EnrollRegistry.feature_enabled?(:vlp_h92)
        expect(subject).to receive(:notify).with(LawfulPresenceDetermination::VLP_VERIFICATION_REQUEST_EVENT_NAME,
                                                 {:person => person, :coverage_start_date => requested_start_date})
        subject.start_vlp_process(requested_start_date)
      end
    end
  end
end

describe LawfulPresenceDetermination do
  context 'publish_updated_event' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:determination) { person.consumer_role.lawful_presence_determination }

    before { determination.citizen_status = 'naturalized_citizen' }

    it 'should trigger publish_updated_event' do
      expect_any_instance_of(Events::Individual::ConsumerRoles::LawfulPresenceDeterminations::Updated).to receive(:publish)
      determination.save!
    end
  end

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
