# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'

# rubocop:disable Metrics/ParameterLists
RSpec.describe ConsumerRole, dbclean: :after_each, type: :model do
  describe "ConsumerRole" do
    it { is_expected.to have_attributes(active_vlp_document_id: nil) }
    it { should delegate_method(:hbx_id).to :person }
    it { should delegate_method(:ssn).to :person }
    it { should delegate_method(:no_ssn).to :person}
    it { should delegate_method(:dob).to :person }
    it { should delegate_method(:gender).to :person }

    it { should delegate_method(:is_incarcerated).to :person }

    it { should delegate_method(:race).to :person }
    it { should delegate_method(:ethnicity).to :person }
    it { should delegate_method(:is_disabled).to :person }

    it { should validate_presence_of :gender }
    it { should validate_presence_of :dob }

    let(:address)       {FactoryBot.build(:address)}
    let(:saved_person)  {FactoryBot.create(:person, gender: 'male', dob: '10/10/1974', ssn: '123456789')}
    let(:saved_person_no_ssn)  {FactoryBot.create(:person, gender: 'male', dob: '10/10/1974', ssn: '', no_ssn: '1')}
    let(:saved_person_no_ssn_invalid)  {FactoryBot.create(:person, gender: 'male', dob: '10/10/1974', ssn: '', no_ssn: '0')}
    let(:is_applicant)          { true }
    let(:citizen_error_message) { 'test citizen_status is not a valid citizen status' }
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:valid_params) do
      { is_applicant: is_applicant, person: saved_person }
    end

    before :each do
      allow(EnrollRegistry[:aca_individual_market].feature).to receive(:is_enabled).and_return(true)
    end

    describe '.new' do

      context 'with no person' do
        let(:params) {valid_params.except(:person)}

        it 'should raise' do
          expect(ConsumerRole.new(**params).valid?).to be_falsey
        end
      end

      context 'with all valid arguments' do
        let(:consumer_role) { saved_person.build_consumer_role(valid_params) }

        it 'should have a default value of native validation as na' do
          expect(consumer_role.native_validation).to eq 'na'
        end

        it 'should save' do
          expect(consumer_role.save).to be_truthy
        end

        context 'and it is saved' do
          before do
            consumer_role.save
          end

          it 'should be findable' do
            expect(ConsumerRole.find(consumer_role.id).id).to eq consumer_role.id
          end

          it 'should have a state of unverified' do
            expect(consumer_role.aasm_state).to eq 'unverified'
          end
        end
      end

      context 'with all valid arguments including no ssn' do
        let(:consumer_role) { saved_person_no_ssn.build_consumer_role(valid_params) }

        it 'should save' do
          expect(consumer_role.save).to be_truthy
        end

        context 'and it is saved' do
          before do
            consumer_role.save
          end

          it 'should be findable' do
            expect(ConsumerRole.find(consumer_role.id).id).to eq consumer_role.id
          end

          it 'should have a state of verifications_pending' do
            expect(consumer_role.aasm_state).to eq 'unverified'
          end
        end

        context "location_residency_verification_type feature" do
          let(:consumer_role) { saved_person.build_consumer_role(valid_params) }

          before do
            allow(EnrollRegistry[:location_residency_verification_type].feature).to receive(:is_enabled).and_return(false)
          end

          it "should not create a location_residency verification type when turned off" do
            expect(consumer_role.verification_types.where(type_name: EnrollRegistry[:enroll_app].setting(:state_residency).item).present?).to eq(false)
          end
        end
      end

      context 'location_residency_verification_type feature is disabled' do
        let(:consumer_role) { saved_person.build_consumer_role(valid_params) }
        before do
          allow(EnrollRegistry[:location_residency_verification_type].feature).to receive(:is_enabled).and_return(false)
        end

        it "should not create a location_residency verification type when turned off" do
          expect(consumer_role.verification_types.where(type_name: EnrollRegistry[:enroll_app].setting(:state_residency).item).present?).to eq(false)
        end
      end
    end
  end

  describe "#find_document" do
    let(:consumer_role) {ConsumerRole.new}
    context 'consumer role does not have any vlp_documents' do
      it 'it creates and returns an empty document of given subject' do
        doc = consumer_role.find_document('Certificate of Citizenship')
        expect(doc).to be_a_kind_of(VlpDocument)
        expect(doc.subject).to eq('Certificate of Citizenship')
      end
    end

    context 'consumer role has a vlp_document' do
      it 'it returns the document' do
        document = consumer_role.vlp_documents.build({subject: 'Certificate of Citizenship'})
        found_document = consumer_role.find_document('Certificate of Citizenship')
        expect(found_document).to be_a_kind_of(VlpDocument)
        expect(found_document).to eq(document)
        expect(found_document.subject).to eq('Certificate of Citizenship')
      end
    end
  end

  describe "update_is_applying_coverage_status" do
    let(:person) {FactoryBot.create(:person, :with_consumer_role)}
    let(:consumer_role) { person.consumer_role }

    it 'should update is_applying_coverage field to false' do
      consumer_role.update_attributes(is_applying_coverage: true)
      consumer_role.update_is_applying_coverage_status("false")
      expect(consumer_role.is_applying_coverage).to eq false
    end

    it 'should not update is_applying_coverage field to false' do
      consumer_role.update_attributes(is_applying_coverage: true)
      consumer_role.update_is_applying_coverage_status("true")
      expect(consumer_role.is_applying_coverage).to eq true
    end
  end

  describe "#find_vlp_document_by_key" do
    let(:person) {FactoryBot.create(:person, :with_consumer_role)}
    let(:consumer_role) { person.consumer_role }
    let(:key) {'sample-key'}
    let(:vlp_document) {VlpDocument.new({subject: 'Certificate of Citizenship', identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:bucket_name##{key}"})}

    context 'has a vlp_document without a file uploaded' do
      before do
        consumer_role.vlp_documents.build({subject: 'Certificate of Citizenship'})
      end

      it 'return no document' do
        found_document = consumer_role.find_vlp_document_by_key(key)
        expect(found_document).to be_nil
      end
    end

    context 'has a vlp_document with a file uploaded' do
      before do
        consumer_role.verification_types.each{|type| type.vlp_documents << vlp_document }
      end

      it 'returns vlp_document document' do
        found_document = consumer_role.find_vlp_document_by_key(key)
        expect(found_document).to eql(vlp_document)
      end
    end

  end

  describe "CRM update" do
    let(:test_person) { FactoryBot.create(:person, :with_consumer_role, last_name: 'John', first_name: 'Doe') }
    let(:test_family) { FactoryBot.create(:family, :with_primary_family_member, :person => test_person) }
    before do
      allow_any_instance_of(Person).to receive(:has_active_consumer_role?).and_return(true)
      allow_any_instance_of(Person).to receive(:primary_family).and_return(test_family)
      allow_any_instance_of(Family).to receive(:primary_person).and_return(test_person)
      allow(EnrollRegistry[:crm_publish_primary_subscriber].feature).to receive(:is_enabled).and_return(true)
    end

    it "calls the PublishPrimarySubscriber operation" do
      expect(::Operations::People::SugarCrm::PublishPrimarySubscriber).to receive(:new).and_call_original
      test_person.trigger_primary_subscriber_publish
    end
  end

  describe "#move_identity_documents_to_outstanding" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role)}
    before do
      person.consumer_role.update!(identity_validation: 'na')
    end

    context 'move to outstanding if initial state is unverified' do

      it 'successfully updates identity and application to outstanding' do
        consumer = person.consumer_role
        consumer.move_identity_documents_to_outstanding
        expect(consumer.identity_validation).to eq 'outstanding'
        expect(consumer.application_validation).to eq 'outstanding'
      end

      it 'should not update dentity and application to outstanding' do
        consumer = person.consumer_role
        consumer.identity_validation = 'valid'
        consumer.application_validation = 'valid'
        consumer.move_identity_documents_to_outstanding
        expect(consumer.identity_validation).to eq 'valid'
        expect(consumer.application_validation).to eq 'valid'
      end
    end
  end

  describe "#find_ridp_document_by_key" do
    let(:person) {Person.new}
    let(:consumer_role) {ConsumerRole.new({person: person})}
    let(:key) {'sample-key'}
    let(:ridp_document) {RidpDocument.new({subject: 'Driver License', identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:bucket_name##{key}"})}

    context 'has a ridp_document without a file uploaded' do
      before do
        consumer_role.ridp_documents.build({subject: 'Driver License'})
      end

      it 'return no document' do
        found_document = consumer_role.find_ridp_document_by_key(key)
        expect(found_document).to be_nil
      end
    end

    context 'has a ridp_document with a file uploaded' do
      before do
        consumer_role.ridp_documents << ridp_document
      end

      it 'returns ridp_document document' do
        found_document = consumer_role.find_ridp_document_by_key(key)
        expect(found_document).to eql(ridp_document)
      end
    end
  end

  describe "#build_nested_models_for_person" do
    let(:person) {FactoryBot.create(:person)}
    let(:consumer_role) {ConsumerRole.new}

    before do
      allow(consumer_role).to receive(:person).and_return person
      consumer_role.build_nested_models_for_person
    end

    it 'should get home and mailing address' do
      expect(person.addresses.map(&:kind)).to include 'home'
      expect(person.addresses.map(&:kind)).to include 'mailing'
    end

    it 'should get home and mobile phone' do
      expect(person.phones.map(&:kind)).to include 'home'
      expect(person.phones.map(&:kind)).to include 'mobile'
    end

    it 'should get emails' do
      Email::KINDS.each do |kind|
        expect(person.emails.map(&:kind)).to include kind
      end
    end
  end

  describe "#latest_active_tax_household_with_year" do
    include_context 'BradyBunchAfterAll'
    let(:family) { FactoryBot.build(:family)}
    let(:consumer_role) { ConsumerRole.new }
    before :all do
      create_tax_household_for_mikes_family
      @consumer_role = mike.consumer_role
      @taxhouhold = mikes_family.latest_household.tax_households.last
    end

    it 'should rerturn active taxhousehold of this year' do
      expect(@consumer_role.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year, mikes_family)).to eq @taxhouhold
    end

    it 'should rerturn nil when can not found taxhousehold' do
      expect(consumer_role.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year, family)).to eq nil
    end
  end

  context 'Verification process and notices' do
    let(:person) {FactoryBot.create(:person, :with_consumer_role)}
    describe "#has_docs_for_type?" do
      before do
        person.consumer_role.vlp_documents = []
      end
      context 'vlp exist but document is NOT uploaded' do
        it 'returns false for vlp doc without uploaded copy' do
          person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :identifier => nil)
          expect(person.consumer_role.has_docs_for_type?('Citizenship')).to be_falsey
        end
        it 'returns false for Immigration type' do
          person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :identifier => nil, :verification_type => 'Immigration type')
          expect(person.consumer_role.has_docs_for_type?('Immigration type')).to be_falsey
        end
      end
      context 'vlp with uploaded copy' do
        it 'returns true if person has uploaded documents for this type' do
          person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :identifier => 'identifier', :verification_type => 'Citizenship')
          expect(person.consumer_role.has_docs_for_type?('Citizenship')).to be_truthy
        end
        it 'returns false if person has NO documents for this type' do
          person.consumer_role.vlp_documents << FactoryBot.build(:vlp_document, :identifier => 'identifier', :verification_type => 'Immigration type')
          expect(person.consumer_role.has_docs_for_type?('Immigration type')).to be_truthy
        end
      end
    end

    describe "#has_ridp_docs_for_type?" do
      before do
        person.consumer_role.ridp_documents = []
      end
      context 'ridp exist but document is NOT uploaded' do
        it 'returns false for ridp doc without uploaded copy' do
          person.consumer_role.ridp_documents << FactoryBot.build(:ridp_document, :identifier => nil)
          expect(person.consumer_role.has_ridp_docs_for_type?('Identity')).to be_falsey
        end
        it 'returns false for Identity type' do
          person.consumer_role.ridp_documents << FactoryBot.build(:ridp_document, :identifier => nil, :ridp_verification_type => 'Identity')
          expect(person.consumer_role.has_ridp_docs_for_type?('Identity')).to be_falsey
        end
      end
      context 'ridp with uploaded copy' do
        it 'returns true if person has uploaded documents for this type' do
          person.consumer_role.ridp_documents << FactoryBot.build(:ridp_document, :identifier => 'identifier', :ridp_verification_type => 'Identity')
          expect(person.consumer_role.has_ridp_docs_for_type?('Identity')).to be_truthy
        end
        it 'returns false if person has NO documents for this type' do
          person.consumer_role.ridp_documents << FactoryBot.build(:ridp_document, :identifier => 'identifier', :ridp_verification_type => 'Identity')
          expect(person.consumer_role.has_ridp_docs_for_type?('Identity')).to be_truthy
        end
      end
    end

    describe 'Native American verification' do
      before do
        allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(false)
      end
      shared_examples_for 'ensures native american field value' do |action, state, consumer_kind, tribe, tribe_state|
        it "#{action} #{state} for #{consumer_kind}" do
          person.update_attributes!(:tribal_id => '444444444') if tribe
          person.consumer_role.update_attributes!(:native_validation => tribe_state) if tribe_state
          expect(person.consumer_role.native_validation).to eq(state)
        end
      end

      context "native american verification types" do
        let!(:person1) { FactoryBot.create(:person, :with_consumer_role, :with_valid_native_american_information) }
        let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person1)}
        let!(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, :with_enrollment_members, family: family, enrollment_members: family.family_members)}

        before do
          allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(true)
          allow(EnrollRegistry[:indian_alaskan_tribe_codes].feature).to receive(:is_enabled).and_return(true)
          allow(EnrollRegistry[:enroll_app].setting(:state_abbreviation)).to receive(:item).and_return('ME')
          person.update_attributes!(tribal_state: "ME", tribe_codes: ["", "PE"])
          v_type = VerificationType.new(type_name: "American Indian Status", validation_status: 'outstanding', inactive: false)
          person1.verification_types << v_type
          person1.save!
        end

        it "does not deactivate native american verification type" do
          ai_an_type = person1.verification_types.where(type_name: "American Indian Status").first
          ai_an_type.update_attributes!(validation_status: 'negative_response_received')
          person1.save!
          expect(ai_an_type.inactive).to eql(false)
        end
      end

      context "native validation doesn't exist" do
        it_behaves_like 'ensures native american field value', 'assigns', 'na', 'NON native american consumer', nil, nil

        it_behaves_like 'ensures native american field value', 'assigns', 'outstanding', 'native american consumer', '444444444', nil
      end
      context 'existing native validation' do
        it_behaves_like 'ensures native american field value', 'assigns', 'pending', 'pending native american consumer', 'tribe', 'pending'
        it_behaves_like 'ensures native american field value', "doesn't change", 'outstanding', 'outstanding native american consumer', 'tribe', 'outstanding'
        it_behaves_like 'ensures native american field value', 'assigns', 'outstanding', 'na native american consumer', 'tribe', 'na'
      end
    end

    describe "#check_tribal_name" do

      before do
        allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(true)
        allow(EnrollRegistry[:indian_alaskan_tribe_codes].feature).to receive(:is_enabled).and_return(true)
        allow(EnrollRegistry[:enroll_app].setting(:state_abbreviation)).to receive(:item).and_return('ME')

      end

      context "tribal state is ME" do

        before do
          person.update_attributes!(tribal_state: "ME", tribe_codes: ["", "PE"])
        end

        it "returns tribal codes" do
          expect(person.consumer_role.check_tribal_name).to eq(["", "PE"])
        end
      end

      context "tribal state is outside ME" do
        before do
          person.update_attributes!(tribal_state: "CA", tribe_codes: [], tribal_name: 'tribal name1')
        end

        it "returns tribal name" do
          expect(person.consumer_role.check_tribal_name).to eq("tribal name1")
        end
      end
    end

    describe 'can_receive_paper_communication?' do

      let(:contact_method) { 'Paper and Electronic communications' }
      let(:consumer_role) { create(:consumer_role, contact_method: contact_method) }
      let(:subject) { consumer_role.can_receive_paper_communication? }

      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return true
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:contact_method_via_dropdown).and_return(contact_method_via_dropdown)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:location_residency_verification_type).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:indian_alaskan_tribe_details).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:check_for_crm_updates).and_return(false)
      end

      context 'when contact_method_via_dropdown feature is enabled' do
        let(:contact_method_via_dropdown) { true }
        let(:contact_method) { 'Paper and Electronic communications' }

        it 'returns true' do
          expect(subject).to be_truthy
        end

        context 'when consumer did not opt for paper' do
          let(:contact_method) { 'Only Electronic communications' }

          it 'returns false' do
            expect(subject).to be_falsey
          end
        end
      end

      context 'when contact_method_via_dropdown feature is disabled' do
        let(:contact_method_via_dropdown) { false }
        let(:contact_method) { 'Paper, Electronic and Text Message communications' }

        it 'returns true' do
          expect(subject).to be_truthy
        end

        context 'when consumer did not opt for paper' do
          let(:contact_method) { 'Electronic and Text Message communications' }

          it 'returns false' do
            expect(subject).to be_falsey
          end
        end
      end
    end

    describe 'can_receive_electronic_communication?' do
      let(:contact_method) { 'Paper and Electronic communications' }
      let(:consumer_role) { create(:consumer_role, contact_method: contact_method) }
      let(:subject) { consumer_role.can_receive_electronic_communication? }

      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return true
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:contact_method_via_dropdown).and_return(contact_method_via_dropdown)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:location_residency_verification_type).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:indian_alaskan_tribe_details).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_return(false)
      end

      context 'when contact_method_via_dropdown feature is enabled' do
        let(:contact_method_via_dropdown) { true }
        let(:contact_method) { 'Paper and Electronic communications' }

        it 'returns true' do
          expect(subject).to be_truthy
        end

        context 'when consumer did not opt for electronic' do
          let(:contact_method) { 'Only Paper communication' }

          it 'returns false' do
            expect(subject).to be_falsey
          end
        end
      end

      context 'when contact_method_via_dropdown feature is disabled' do
        let(:contact_method_via_dropdown) { false }
        let(:contact_method) { 'Paper, Electronic and Text Message communications' }

        it 'returns true' do
          expect(subject).to be_truthy
        end

        context 'when consumer did not opt for electronic' do
          let(:contact_method) { 'Paper and Text Message communications' }

          it 'returns false' do
            expect(subject).to be_falsey
          end
        end
      end
    end

    describe 'state machine transactions for failed payload' do
      let(:consumer) { person.consumer_role }
      let(:verification_types) { consumer.verification_types }
      let(:verification_attr) { OpenStruct.new({ :determined_at => Time.zone.now, :vlp_authority => 'hbx' })}

      before :each do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:ssa_h3).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:vlp_h92).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_errors).and_return(true)
      end

      context 'success payload' do
        shared_examples_for 'IVL state machine transitions and verification_types validation_status' do |ssn, citizen, from_state, to_state, event, type_name, verification_type_validation_status|
          before do
            allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(false)
            person.ssn = ssn
            consumer.citizen_status = citizen
          end

          it "moves from #{from_state} to #{to_state} on #{event}" do
            expect(consumer).to transition_from(from_state).to(to_state).on_event(event.to_sym, verification_attr)
            expect(consumer.verification_types.where(:type_name.in => type_name).first.validation_status).to eq verification_type_validation_status
          end
        end

        # DHS calls will not made for people who are 'us_citizen'
        context 'coverage_purchased_no_residency with us_citizen' do
          it_behaves_like 'IVL state machine transitions and verification_types validation_status', '999001234', 'us_citizen', :unverified, :verification_outstanding, 'coverage_purchased_no_residency!', ["Social Security Number"],
                          "negative_response_received"
          it_behaves_like 'IVL state machine transitions and verification_types validation_status', '999001234', 'us_citizen', :unverified, :verification_outstanding, 'coverage_purchased_no_residency!', ["Citizenship"], "negative_response_received"
          it_behaves_like 'IVL state machine transitions and verification_types validation_status', '111111111', 'us_citizen', :unverified, :ssa_pending, 'coverage_purchased_no_residency!', ["Social Security Number"], "pending"
          it_behaves_like 'IVL state machine transitions and verification_types validation_status', '111111111', 'us_citizen', :unverified, :ssa_pending, 'coverage_purchased_no_residency!', ["Citizenship"], "unverified"
        end

        # DHS calls will be made for people who are 'naturalized_citizen'
        context 'coverage_purchased_no_residency with naturalized_citizen' do
          it_behaves_like 'IVL state machine transitions and verification_types validation_status', '999001234', 'naturalized_citizen', :unverified, :verification_outstanding, 'coverage_purchased_no_residency!', ["Social Security Number"],
                          "negative_response_received"
          it_behaves_like 'IVL state machine transitions and verification_types validation_status', '999001234', 'naturalized_citizen', :unverified, :verification_outstanding, 'coverage_purchased_no_residency!', ["Citizenship"], "pending"
          it_behaves_like 'IVL state machine transitions and verification_types validation_status', '111111111', 'naturalized_citizen', :unverified, :ssa_pending, 'coverage_purchased_no_residency!', ["Social Security Number"], "pending"
          it_behaves_like 'IVL state machine transitions and verification_types validation_status', '111111111', 'naturalized_citizen', :unverified, :ssa_pending, 'coverage_purchased_no_residency!', ["Citizenship"], "pending"
        end
      end

      context 'failure payload' do
        let(:ssa_validator) { instance_double(Operations::Fdsh::Ssa::H3::RequestSsaVerification) }
        let(:vlp_validator) { instance_double(Operations::Fdsh::Vlp::H92::RequestInitialVerification) }

        shared_examples_for 'IVL state machine transitions and verification_types validation_status' do |ssn, citizen, from_state, to_state, event, type_name, verification_type_validation_status|
          before do
            allow(ssa_validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid payload'))
            allow(Operations::Fdsh::Ssa::H3::RequestSsaVerification).to receive(:new).and_return(ssa_validator)
            allow(vlp_validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid payload'))
            allow(Operations::Fdsh::Vlp::H92::RequestInitialVerification).to receive(:new).and_return(vlp_validator)
            allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(false)
            person.ssn = ssn
            consumer.citizen_status = citizen
          end

          it "moves from #{from_state} to #{to_state} on #{event}" do
            expect(consumer).to transition_from(from_state).to(to_state).on_event(event.to_sym, verification_attr)
            expect(consumer.verification_types.where(:type_name.in => type_name).first.validation_status).to eq verification_type_validation_status
          end
        end

        context 'coverage_purchased_no_residency' do
          it_behaves_like 'IVL state machine transitions and verification_types validation_status', '999001234', 'us_citizen', :unverified, :verification_outstanding, 'coverage_purchased_no_residency!', ["Social Security Number"],
                          "negative_response_received"
          it_behaves_like 'IVL state machine transitions and verification_types validation_status', '999001234', 'us_citizen', :unverified, :verification_outstanding, 'coverage_purchased_no_residency!', ["Citizenship"], "negative_response_received"
          it_behaves_like 'IVL state machine transitions and verification_types validation_status', '111111111', 'us_citizen', :unverified, :verification_outstanding, 'coverage_purchased_no_residency!', ["Social Security Number"],
                          "negative_response_received"
          it_behaves_like 'IVL state machine transitions and verification_types validation_status', '111111111', 'us_citizen', :unverified, :verification_outstanding, 'coverage_purchased_no_residency!', ["Citizenship"], "negative_response_received"
        end
      end
    end

    describe 'state machine' do
      let(:consumer) { person.consumer_role }
      let(:verification_types) { consumer.verification_types }
      let(:verification_attr) { OpenStruct.new({ :determined_at => Time.zone.now, :vlp_authority => 'hbx' })}
      all_states = [:unverified, :ssa_pending, :dhs_pending, :verification_outstanding, :fully_verified, :sci_verified, :verification_period_ended]
      shared_examples_for 'IVL state machine transitions and workflow' do |ssn, citizen, residency, residency_status, from_state, to_state, event, tribal_id = ''|
        before do
          allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(false)
          person.ssn = ssn
          consumer.citizen_status = citizen
          consumer.is_state_resident = residency
          consumer.tribal_id = tribal_id
          consumer.local_residency_validation = residency_status
        end
        it "moves from #{from_state} to #{to_state} on #{event}" do
          expect(consumer).to transition_from(from_state).to(to_state).on_event(event.to_sym, verification_attr)
        end
      end

      context 'import' do
        all_states.each do |state|
          it_behaves_like 'IVL state machine transitions and workflow', nil, nil, nil, 'pending', state, :fully_verified, 'import!'
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'us_citizen', true, 'valid', state, :fully_verified, 'import!'
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'naturalized_citizen', true, 'valid', state, :fully_verified, 'import!'
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'alien_lawfully_present', true, 'valid', state, :fully_verified, 'import!'
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'lawful_permanent_resident', false, 'outstanding', state, :fully_verified, 'import!'
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'any', true, 'valid', state, :fully_verified, 'import!'
          it_behaves_like 'IVL state machine transitions and workflow', nil, 'any', false, 'outstanding', state, :fully_verified, 'import!'
          it 'updates all verification types with callback' do
            consumer.import!
            expect(consumer.all_types_verified?).to eq true
          end
        end
      end

      context 'coverage_purchased' do
        describe 'citizen with ssn' do
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'us_citizen', false, 'outstanding', :unverified, :ssa_pending, 'coverage_purchased!'
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'us_citizen', true, 'valid', :unverified, :ssa_pending, 'coverage_purchased!'
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'naturalized_citizen', false, 'outstanding', :unverified, :ssa_pending, 'coverage_purchased!'
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'naturalized_citizen', true, 'valid', :unverified, :ssa_pending, 'coverage_purchased!'
        end
        describe 'citizen with NO ssn' do
          it_behaves_like 'IVL state machine transitions and workflow', nil, 'naturalized_citizen', true, 'valid', :unverified, :dhs_pending, 'coverage_purchased!'
          it_behaves_like 'IVL state machine transitions and workflow', nil, 'naturalized_citizen', false, 'outstanding', :unverified, :dhs_pending, 'coverage_purchased!'
          it_behaves_like 'IVL state machine transitions and workflow', nil, 'us_citizen', false, 'outstanding', :unverified, :verification_outstanding, 'coverage_purchased!'
          it_behaves_like 'IVL state machine transitions and workflow', nil, 'us_citizen', true,  'valid', :unverified, :verification_outstanding, 'coverage_purchased!'
          it 'update ssn with callback fail_ssa_for_no_ssn' do
            allow(person).to receive(:ssn).and_return nil
            allow(consumer).to receive(:citizen_status).and_return 'us_citizen'
            consumer.coverage_purchased! verification_attr
            expect(consumer.ssn_validation).to eq('na')
          end
        end
        describe 'immigrant with ssn' do
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'alien_lawfully_present', true, 'valid', :unverified, :ssa_pending, 'coverage_purchased!'
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'alien_lawfully_present', false, 'outstanding', :unverified, :ssa_pending, 'coverage_purchased!'
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'lawful_permanent_resident', false, 'outstanding', :unverified, :ssa_pending, 'coverage_purchased!'
          it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'lawful_permanent_resident', true, 'valid', :unverified, :ssa_pending, 'coverage_purchased!'
        end
        describe "immigrant with NO ssn" do
          it_behaves_like "IVL state machine transitions and workflow", nil, "alien_lawfully_present", true,  "valid", :unverified, :dhs_pending, "coverage_purchased!"
          it_behaves_like "IVL state machine transitions and workflow", nil, "alien_lawfully_present", false, "outstanding", :unverified, :dhs_pending, "coverage_purchased!"
          it_behaves_like "IVL state machine transitions and workflow", nil, "lawful_permanent_resident", false, "outstanding", :unverified, :dhs_pending, "coverage_purchased!"
          it_behaves_like "IVL state machine transitions and workflow", nil, "lawful_permanent_resident", true, "valid", :unverified, :dhs_pending, "coverage_purchased!"

          context "not_lawfully_present_in_us" do

            before do
              allow(person).to receive(:ssn).and_return nil
              allow(consumer).to receive(:citizen_status).and_return "not_lawfully_present_in_us"
              consumer.lawful_presence_determination.update_attributes!(citizen_status: "not_lawfully_present_in_us")
              consumer.coverage_purchased! verification_attr
              consumer.reload
              consumer.fail_dhs! verification_attr
              consumer.reload
            end

            it "should store QNC result" do
              expect(consumer.aasm_state).not_to be "unverified"
            end
          end
        end

        describe "indian tribe member with ssn" do
          it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", true, nil, :unverified, :verification_outstanding, "coverage_purchased!", "232332431"
          it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", false, nil, :unverified, :verification_outstanding, "coverage_purchased!", "232332431"
        end

        describe "indian tribe member with NO ssn" do
          it_behaves_like "IVL state machine transitions and workflow", nil, "us_citizen", true, nil, :unverified, :verification_outstanding, "coverage_purchased!", "232332431"
          it_behaves_like "IVL state machine transitions and workflow", nil, "us_citizen", false, nil, :unverified, :verification_outstanding, "coverage_purchased!", "232332431"
        end

        describe "pending verification type updates" do
          it "updates validation status to pending for unverified consumers" do
            consumer.coverage_purchased!
            expect(consumer.verification_types.map(&:validation_status)).to eq(["pending", "pending", "pending"])
          end

          it "updates indian tribe validition status to negative_response_received and to pending for the rest" do
            consumer.tribal_id = "345543345"
            consumer.coverage_purchased!
            consumer.verification_types.each do |verif|
              case verif.type_name
              when 'American Indian Status'
                expect(verif.validation_status).to eq('negative_response_received')
              when 'Citizenship'
                # Validation Status stays same as we will not make DHS call for people who are 'us_citizen'
                expect(verif.validation_status).to eq('unverified')
              else
                expect(verif.validation_status).to eq('pending')
              end
            end
          end

        end
      end

      context "ssn_invalid" do
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", true, "valid", :ssa_pending, :verification_outstanding, "ssn_invalid!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "lawful_permanent_resident", true, "valid", :ssa_pending, :verification_outstanding, "ssn_invalid!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", true, "valid", :ssa_pending, :verification_outstanding, "ssn_invalid!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", true, "valid", :ssa_pending, :verification_outstanding, "ssn_invalid!"

        context 'fails ssn when verification type is already in review' do
          before do
            verification_types.by_name("Social Security Number").first.update_attributes(validation_status: 'review')
            consumer.aasm_state = "ssa_pending"
            consumer.ssn_invalid! verification_attr
          end

          it 'should remain in review' do
            expect(verification_types.all.by_name("Social Security Number").detect { |vt| vt.validation_status == "review" }.present?).to eq(true)
          end
        end

        it "fails ssn with callback" do
          consumer.aasm_state = "ssa_pending"
          consumer.ssn_invalid! verification_attr
        end
        it "fails lawful presence with callback" do
          consumer.aasm_state = "ssa_pending"
          consumer.ssn_invalid! verification_attr
          expect(consumer.lawful_presence_determination.aasm_state).to eq("verification_outstanding")
        end
      end

      context "ssn_valid_citizenship_invalid" do
        describe "citizen" do
          it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", true, "valid", :ssa_pending, :verification_outstanding, "ssn_valid_citizenship_invalid!"
          it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", false, "outstanding", :ssa_pending, :verification_outstanding, "ssn_valid_citizenship_invalid!"
        end
        describe "immigrant" do
          it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", true, "valid", :ssa_pending, :dhs_pending, "ssn_valid_citizenship_invalid!"
          it_behaves_like "IVL state machine transitions and workflow", "111111111", "lawful_permanent_resident", true, "valid", :ssa_pending, :dhs_pending, "ssn_valid_citizenship_invalid!"
          it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", true, "valid", :ssa_pending, :dhs_pending, "ssn_valid_citizenship_invalid!"
          it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", false, "outstanding", :ssa_pending, :dhs_pending, "ssn_valid_citizenship_invalid!"
          it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", false, "outstanding", :ssa_pending, :dhs_pending, "ssn_valid_citizenship_invalid!"
        end

        it "updates ssn validation with callback" do
          consumer.aasm_state = "ssa_pending"
          consumer.ssn_valid_citizenship_invalid! verification_attr
          expect(verification_types.by_name("Social Security Number").first.validation_status).to eq("verified")
        end

        it "fails lawful presence with callback" do
          consumer.aasm_state = "ssa_pending"
          consumer.ssn_valid_citizenship_invalid! verification_attr
          expect(consumer.lawful_presence_determination.aasm_state).to eq("verification_outstanding")
        end

        it "doesn't change user's citizen input" do
          consumer.aasm_state = "ssa_pending"
          consumer.citizen_status = "alien_lawfully_present"
          consumer.ssn_valid_citizenship_invalid! verification_attr
          expect(consumer.lawful_presence_determination.citizen_status).to eq("alien_lawfully_present")
          expect(consumer.lawful_presence_determination.citizenship_result).to eq("not_lawfully_present_in_us")
        end
      end

      context "ssn_valid_citizenship_valid" do
        before :each do
          consumer.lawful_presence_determination.deny! verification_attr
          consumer.citizen_status = "alien_lawfully_present"
        end
        [false, nil, true].each do |residency|
          if residency
            residency_status = "valid"
            to_state = :fully_verified
          elsif residency.nil?
            residency_status = "pending"
            to_state = :sci_verified
          else
            residency_status = "outstanding"
            to_state = :verification_outstanding
          end
          describe "residency #{residency} #{'pending' if residency.nil?}" do
            [:unverified, :ssa_pending, :verification_outstanding].each do |from_state|
              it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", residency, residency_status, from_state, to_state, "ssn_valid_citizenship_valid!"
              it "updates ssn citizenship with callback and doesn't change consumer citizen input" do
                consumer.ssn_valid_citizenship_valid! verification_attr
                expect(verification_types.by_name("Social Security Number").first.validation_status).to eq("verified")
                expect(consumer.lawful_presence_determination.verification_successful?).to eq true
                expect(consumer.lawful_presence_determination.citizen_status).to eq "alien_lawfully_present"
              end
            end
          end
        end
      end

      context "dhs_pending transition" do
        let(:consumer_role) { person.consumer_role }
        before do
          person.consumer_role.aasm_state = "dhs_pending"
          consumer.lawful_presence_determination.deny! verification_attr
          consumer.citizen_status = "naturalized_citizen"
        end

        it "updates citizenship with callback" do
          consumer.verify_ivl_by_admin([nil])
          expect(consumer.lawful_presence_determination.verification_successful?).to eq true
        end
      end

      context "fail_dhs" do
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "lawful_permanent_resident", true, "valid", :dhs_pending, :verification_outstanding, "fail_dhs!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", false, "outstanding", :dhs_pending, :verification_outstanding, "fail_dhs!"
        it_behaves_like "IVL state machine transitions and workflow", "111111111", "naturalized_citizen", true,"valid", :dhs_pending, :verification_outstanding, "fail_dhs!"

        it "fails lawful presence with callback" do
          consumer.aasm_state = "dhs_pending"
          consumer.fail_dhs! verification_attr
          expect(consumer.lawful_presence_determination.aasm_state).to eq("verification_outstanding")
        end

        context 'fails dhs when verification type is already in review' do
          before do
            verification_types.reject{|type| VerificationType::NON_CITIZEN_IMMIGRATION_TYPES.include? type.type_name }.each{ |type| type.update_attributes(validation_status: 'review') }
            consumer.aasm_state = "dhs_pending"
            consumer.fail_dhs! verification_attr
          end
          it 'should remain in review' do
            expect(verification_types.reject{|type| VerificationType::NON_CITIZEN_IMMIGRATION_TYPES.include? type.type_name }.each{ |type| ['review'].include?(type.validation_status) }).to be_truthy
          end
        end
      end

      context "pass_dhs" do
        before :each do
          consumer.lawful_presence_determination.deny! verification_attr
          consumer.citizen_status = "alien_lawfully_present"
        end
        [false, nil, true].each do |residency|
          if residency
            residency_status = "valid"
            to_state = :fully_verified
          elsif residency.nil?
            residency_status = "pending"
            to_state = :sci_verified
          else
            residency_status = "outstanding"
            to_state = :verification_outstanding
          end
          describe "residency #{residency} #{'pending' if residency.nil?}" do
            [:unverified, :dhs_pending, :verification_outstanding].each do |from_state|
              it_behaves_like "IVL state machine transitions and workflow", nil, "naturalized_citizen", residency, residency_status, from_state, to_state, "pass_dhs!"
              it_behaves_like "IVL state machine transitions and workflow", "111111111", "alien_lawfully_present", residency,residency_status, from_state, to_state, "pass_dhs!"
              it "updates citizenship with callback and doesn't change consumer citizen input" do
                consumer.pass_dhs! verification_attr
                expect(consumer.lawful_presence_determination.verification_successful?).to eq true
                expect(consumer.lawful_presence_determination.citizen_status).to eq "alien_lawfully_present"
              end
            end
          end
        end
      end

      context "pass_residency" do
        [nil, "111111111"].each do |ssn|
          it_behaves_like "IVL state machine transitions and workflow", ssn, "us_citizen", true, "valid", :unverified, :verification_outstanding, "fail_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "lawful_permanent_resident", true, "valid", :ssa_pending, :ssa_pending, "fail_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", true, "valid",  :dhs_pending, :dhs_pending, "fail_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "naturalized_citizen", false, "outstanding", :sci_verified, :verification_outstanding, "fail_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", false, "outstanding", :verification_outstanding, :verification_outstanding, "fail_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", false, "outstanding", :fully_verified, :verification_outstanding, "fail_residency!"
          it "updates residency status with callback" do
            consumer.is_state_resident = true
            consumer.fail_residency!
            expect(consumer.is_state_resident).to be false
          end
        end
      end

      context "fail_residency" do
        [nil, "111111111"].each do |ssn|
          it_behaves_like "IVL state machine transitions and workflow", ssn, "us_citizen", true, "valid", :unverified, :verification_outstanding, "fail_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "lawful_permanent_resident", true, "valid", :ssa_pending, :ssa_pending, "fail_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", true, "valid", :dhs_pending, :dhs_pending, "fail_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "naturalized_citizen", false, "outstanding", :sci_verified, :verification_outstanding, "fail_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", false, "outstanding", :verification_outstanding, :verification_outstanding, "fail_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", false, "outstanding", :fully_verified, :verification_outstanding, "fail_residency!"
          it "updates residency status with callback" do
            consumer.is_state_resident = true
            consumer.fail_residency! verification_attr
            expect(consumer.is_state_resident).to be false
          end

          context 'fails residency when verification type is already in review' do
            before do
              verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first.update_attributes(validation_status: 'review')
              consumer.is_state_resident = true
              consumer.fail_residency! verification_attr
            end
            it 'should remain in review' do
              expect(verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first.validation_status).to eq 'review'
            end
          end
        end
      end

      context "trigger_residency" do
        [nil, "111111111"].each do |ssn|
          it_behaves_like "IVL state machine transitions and workflow", ssn, "lawful_permanent_resident", true, "valid", :ssa_pending, :ssa_pending, "trigger_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "lawful_permanent_resident", true, "valid", :unverified, :unverified, "trigger_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", true, "valid", :dhs_pending, :dhs_pending, "trigger_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "naturalized_citizen", false, "outstanding", :sci_verified, :sci_verified, "trigger_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", false, "outstanding", :verification_outstanding, :verification_outstanding, "trigger_residency!"
          it_behaves_like "IVL state machine transitions and workflow", ssn, "alien_lawfully_present", false, "outstanding", :fully_verified, :sci_verified, "trigger_residency!"
          it "updates residency status with callback" do
            if consumer.may_trigger_residency?
              consumer.is_state_resident = true
              consumer.trigger_residency!
              expect(consumer.is_state_resident).to be nil
            end
          end
        end
      end

      context "revert" do
        before :each do
          consumer.import! verification_attr
        end

        all_states.each do |state|
          it_behaves_like "IVL state machine transitions and workflow", "111111111", "us_citizen", true, "valid", state, :unverified, "revert!"
          it "updates ssn" do
            consumer.revert!
            expect(consumer.ssn_validation).to eq "pending"
          end

          it "updates lawful presence status" do
            consumer.revert!
            expect(consumer.lawful_presence_determination.verification_pending?).to eq true
          end
          it "updates residency status" do
            consumer.revert!
            expect(consumer.is_state_resident?).to eq true
          end
        end
      end

      context 'coverage_purchased_no_residency' do
        it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'us_citizen', false, "outstanding", :unverified, :ssa_pending, 'coverage_purchased_no_residency!'
        it_behaves_like 'IVL state machine transitions and workflow', '111111111', 'naturalized_citizen', false, "outstanding", :unverified, :ssa_pending, 'coverage_purchased_no_residency!'
        it_behaves_like 'IVL state machine transitions and workflow', nil, 'alien_lawfully_present', true, "valid", :unverified, :dhs_pending, 'coverage_purchased_no_residency!'
        it_behaves_like 'IVL state machine transitions and workflow', nil, 'alien_lawfully_present', false, "outstanding", :unverified, :dhs_pending, 'coverage_purchased_no_residency!'
      end
    end

    describe "verification types" do
      let(:person) {FactoryBot.create(:person, :with_consumer_role) }
      let(:consumer) { person.consumer_role }

      shared_examples_for "collecting verification types for person" do |v_types, types_count, ssn, citizen, native, age|
        before do
          allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(false)
          person.ssn = nil unless ssn
          person.us_citizen = citizen
          person.dob = TimeKeeper.date_of_record - age.to_i.years
          person.tribal_id = "444444444" if native
          person.citizen_status = "indian_tribe_member" if native
          person.consumer_role.save
        end
        it "returns array of verification types" do
          expect(person.verification_types.class).to be Array
        end

        it "returns #{types_count} verification types" do
          expect(consumer.verification_types.count).to eq types_count
        end

        it "contains #{v_types} verification types" do
          expect(consumer.verification_types.map(&:type_name)).to eq v_types
        end
      end

      context "SSN + Citizen" do
        it_behaves_like "collecting verification types for person", [VerificationType::LOCATION_RESIDENCY, "Social Security Number", "Citizenship"], 3, "2222222222", true, nil, 25
      end

      context "SSN + Immigrant" do
        it_behaves_like "collecting verification types for person", [VerificationType::LOCATION_RESIDENCY, "Social Security Number", "Immigration status"], 3, "2222222222", false, nil, 20
      end

      context "SSN + Native Citizen" do
        it_behaves_like "collecting verification types for person", [VerificationType::LOCATION_RESIDENCY, "Social Security Number", "Citizenship", "American Indian Status"], 4, "2222222222", true, "native", 20
      end

      context "Citizen with NO SSN" do
        it_behaves_like "collecting verification types for person", [VerificationType::LOCATION_RESIDENCY, "Citizenship"], 2, nil, true, nil, 20
      end

      context "Immigrant with NO SSN" do
        it_behaves_like "collecting verification types for person", [VerificationType::LOCATION_RESIDENCY, "Immigration status"], 2, nil, false, nil, 20
      end

      context "Native Citizen with NO SSN" do
        it_behaves_like "collecting verification types for person", [VerificationType::LOCATION_RESIDENCY, "Citizenship", "American Indian Status"], 3, nil, true, "native", 20
      end
    end

    describe "#check_native_status" do
      let(:person) {FactoryBot.create(:person, :with_consumer_role)}
      let(:consumer_role) {person.consumer_role}
      let(:family) { double("Family", :person_has_an_active_enrollment? => true)}

      before do
        allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(false)
      end
      it 'should fail indian tribe status if person updates native status field' do
        person.update_attributes(tribal_id: "1234567")
        consumer_role.update_attributes(aasm_state: "ssa_pending")
        consumer_role.check_native_status(family, true)
        expect(consumer_role.verification_types.map(&:type_name)).to include('American Indian Status')
        expect(consumer_role.aasm_state).to include('verification_outstanding')
      end

      it 'should fail indian tribe status if no change in native status' do
        consumer_role.update_attributes(aasm_state: "ssa_pending")
        consumer_role.check_native_status(family, true)
        expect(consumer_role.verification_types.map(&:type_name)).not_to include('American Indian Status')
        expect(consumer_role.aasm_state).to include('ssa_pending')
      end

    end

    describe "#check_for_critical_changes" do
      sensitive_fields = ConsumerRole.new.verification_sensitive_attributes
      all_fields = FactoryBot.build(:person, :encrypted_ssn => "111111111", :gender => "male", "updated_by_id": "any").attributes.keys
      mask_hash = all_fields.map{|v| [v, (sensitive_fields.include?(v) ? "call" : "don't call")]}.to_h
      subject { ConsumerRole.new(:person => person) }
      let(:family) { double("Family", :person_has_an_active_enrollment? => true)}
      shared_examples_for "reping the hub fo critical changes" do |field, call, params|
        it "#{call} the hub if #{field} record was changed" do
          allow(Person).to receive(:person_has_an_active_enrollment?).and_return true
          allow(subject.person).to receive(:is_consumer_role_active?).and_return false
          if call == "call"
            expect(subject).to receive(:redetermine_verification!)
          else
            expect(subject).to_not receive(:redetermine_verification!)
          end
          subject.check_for_critical_changes(family, info_changed: subject.sensitive_information_changed?(params))
        end
      end
      mask_hash.each do |field, action|
        value = field == "dob" ? "2016-08-08" : "new filed record"
        it_behaves_like "reping the hub fo critical changes", field, action, {field => value}
      end
    end
  end

  describe "#revert_lawful_presence" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:consumer) { person.consumer_role }
    let(:verification_types) { consumer.verification_types }
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.zone.now, :vlp_authority => "hbx" })}

    it "should move Citizenship verification type to pending state" do
      consumer.lawful_presence_determination.authorize!(verification_attr)
      consumer.revert_lawful_presence(verification_attr)
      expect(consumer.lawful_presence_determination.aasm_state).to eq "verification_pending"
      expect(consumer.verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first.validation_status).to eq "unverified"
      expect(consumer.verification_types.by_name("Social Security Number").first.validation_status).to eq "unverified"
      expect(consumer.verification_types.by_name("Citizenship").first.validation_status).to eq "pending"
    end
  end

  describe "it should check the residency status" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
    let(:consumer) { person.consumer_role }
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.zone.now, :vlp_authority => "hbx" })}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person) }
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01') }
    let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, product: product, household: family.active_household, aasm_state: "coverage_selected", kind: 'individual') }
    let!(:hbx_enrollment_member) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment) }
    let!(:enrollment) {consumer.person.primary_family.active_household.hbx_enrollments.first}
    context "consumer role should check for eligibility" do
      it "should move the enrollment to unverified" do
        consumer.coverage_purchased!
        expect(consumer.aasm_state).to eq("ssa_pending")
        enrollment.reload
        expect(enrollment.aasm_state).to eq("unverified")
      end

      it "should update the consumer and enrollment state when ssn and citizenship is valid" do
        consumer.coverage_purchased!
        consumer.ssn_valid_citizenship_valid!(verification_attr)
        expect(consumer.aasm_state).to eq("sci_verified")
        enrollment.reload
        expect(enrollment.aasm_state).to eq("unverified")
      end

      it "should set is_any_enrollment_member_outstanding to true when received negative response from residency hub" do
        consumer.coverage_purchased!
        consumer.ssn_valid_citizenship_valid!(verification_attr)
        consumer.fail_residency!
        expect(consumer.aasm_state).to eq("verification_outstanding")
        enrollment.reload
        expect(enrollment.aasm_state).to eq("coverage_selected")
        expect(enrollment.is_any_enrollment_member_outstanding).to eq(true)
      end

      it "should move the enrollment status to contingent when received negative response from residency hub" do
        consumer.coverage_purchased!
        consumer.ssn_valid_citizenship_valid!(verification_attr)
        consumer.pass_residency!
        expect(consumer.aasm_state).to eq("fully_verified")
        enrollment.reload
        expect(enrollment.aasm_state).to eq("coverage_selected")
      end
    end
  end

  describe "#find_document" do
    let(:consumer_role) {ConsumerRole.new}
    context "consumer role does not have any vlp_documents" do
      it "it creates and returns an empty document of given subject" do
        doc = consumer_role.find_document("Certificate of Citizenship")
        expect(doc).to be_a_kind_of(VlpDocument)
        expect(doc.subject).to eq("Certificate of Citizenship")
      end
    end

    context "consumer role has a vlp_document" do
      it "it returns the document" do
        document = consumer_role.vlp_documents.build({subject: "Certificate of Citizenship"})
        found_document = consumer_role.find_document("Certificate of Citizenship")
        expect(found_document).to be_a_kind_of(VlpDocument)
        expect(found_document).to eq(document)
        expect(found_document.subject).to eq("Certificate of Citizenship")
      end
    end
  end

  describe "Indian tribe member" do
    before do
      allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(false)
    end
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:consumer_role) { person.consumer_role }
    let(:verification_types) { consumer.verification_types }
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.zone.now, :vlp_authority => "ssa" })}

    context 'Responses from local hub and ssa hub' do
      it 'aasm state should be in fully_verified if dc response is valid and consumer is tribe member' do
        person.update_attributes!(tribal_id: "12345")
        consumer_role.coverage_purchased!(verification_attr)
        consumer_role.pass_residency!
        consumer_role.ssn_valid_citizenship_valid!(verification_attr)
        expect(consumer_role.aasm_state).to eq 'fully_verified'
      end

      it 'aasm state should be in fully verified if dc response is valid and consumer is not a tribe member' do
        consumer_role.fail_residency!
        consumer_role.ssn_valid_citizenship_valid!(verification_attr)
        expect(consumer_role.aasm_state).to eq 'verification_outstanding'
      end

      it 'aasm state should be in verification_outstanding if dc response is negative and consumer is not a tribe member' do
        consumer_role.fail_residency!
        consumer_role.ssn_valid_citizenship_valid!(verification_attr)
        expect(consumer_role.aasm_state).to eq 'verification_outstanding'
      end

      it 'aasm state should be in fully verified if dc response is positive and consumer is not a tribe member' do
        consumer_role.update_attributes(is_state_resident: nil)
        consumer_role.ssn_valid_citizenship_valid!(verification_attr)
        consumer_role.pass_residency!
        expect(consumer_role.aasm_state).to eq 'fully_verified'
      end

      it 'aasm state should be in verification_outstanding if dc response is positive and consumer is a tribe member' do
        consumer_role.update_attributes(is_state_resident: nil)
        person.update_attributes!(tribal_id: "12345")
        consumer_role.ssn_valid_citizenship_valid!(verification_attr)
        consumer_role.pass_residency!
        expect(consumer_role.aasm_state).to eq 'verification_outstanding'
      end
    end

    context 'american indian verification type on coverage purchase' do
      it 'aasm state should be in verification negative_response_received and american indian status in outstanding upon coverage purchase' do
        person.update_attributes!(tribal_id: "12345")
        consumer_role.coverage_purchased!(verification_attr)
        american_indian_status = consumer_role.verification_types.by_name("American Indian Status").first
        expect(american_indian_status.validation_status).to eq 'negative_response_received'
        expect(consumer_role.aasm_state).to eq 'verification_outstanding'
      end
    end

    context 'admin verifies american indian status' do
      it 'consumer aasm state should be in fully_verified if all verification types are verified' do
        person.update_attributes!(tribal_id: "12345")
        consumer_role.coverage_purchased!(verification_attr)
        consumer_role.pass_residency!
        consumer_role.ssn_valid_citizenship_valid!(verification_attr)
        american_indian_status = consumer_role.verification_types.by_name("American Indian Status").first
        consumer_role.update_verification_type(american_indian_status, "admin verified")
        expect(consumer_role.aasm_state).to eq 'fully_verified'
        expect(american_indian_status.validation_status).to eq 'verified'
        expect(consumer_role.lawful_presence_determination.vlp_authority).to eq 'ssa'
      end
    end

    context 'admin rejects american indian status document' do
      it 'consumer aasm state should be in fully_verified if all verification types are verified' do
        person.update_attributes!(tribal_id: "12345")
        consumer_role.coverage_purchased!(verification_attr)
        consumer_role.pass_residency!
        consumer_role.ssn_valid_citizenship_valid!(verification_attr)
        american_indian_status = consumer_role.verification_types.by_name("American Indian Status").first
        consumer_role.return_doc_for_deficiency(american_indian_status, 'Invalid Document')
        expect(consumer_role.aasm_state).to eq 'verification_outstanding'
        expect(american_indian_status.validation_status).to eq 'rejected'
        expect(consumer_role.lawful_presence_determination.vlp_authority).to eq 'ssa'
      end
    end

  end

  describe "#find_vlp_document_by_key" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role)}
    let(:consumer_role) { person.consumer_role }
    let(:key) {"sample-key"}
    let(:vlp_document) {VlpDocument.new({subject: "Certificate of Citizenship", identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:bucket_name##{key}"})}

    context "has a vlp_document without a file uploaded" do
      before do
        consumer_role.vlp_documents.build({subject: "Certificate of Citizenship"})
      end

      it "return no document" do
        found_document = consumer_role.find_vlp_document_by_key(key)
        expect(found_document).to be_nil
      end
    end

    context "has a vlp_document with a file uploaded" do
      before do
        consumer_role.verification_types.each{|type| type.vlp_documents << vlp_document }
      end

      it "returns vlp_document document" do
        found_document = consumer_role.find_vlp_document_by_key(key)
        expect(found_document).to eql(vlp_document)
      end
    end
  end

  describe "#build_nested_models_for_person" do
    let(:person) {FactoryBot.create(:person)}
    let(:consumer_role) {ConsumerRole.new}

    before do
      allow(consumer_role).to receive(:person).and_return person
      consumer_role.build_nested_models_for_person
    end

    it "should get home and mailing address" do
      expect(person.addresses.map(&:kind)).to include "home"
      expect(person.addresses.map(&:kind)).to include 'mailing'
    end

    it "should get home and mobile phone" do
      expect(person.phones.map(&:kind)).to include "home"
      expect(person.phones.map(&:kind)).to include "mobile"
    end

    it "should get emails" do
      Email::KINDS.each do |kind|
        expect(person.emails.map(&:kind)).to include kind
      end
    end
  end

  describe "can_trigger_residency?" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
    let(:consumer_role) { person.consumer_role }
    let(:residency_verification_type) {consumer_role.verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:enrollment) { double("HbxEnrollment", aasm_state: "coverage_selected")}
    let(:hub_request) {EventRequest.new}

    context "when person has age > 19 & has an active coverage" do

      before :each do
        allow(family).to receive(:person_has_an_active_enrollment?).and_return true
      end

      it "should return true if there is a change in address from non-dc to dc" do
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "0", is_temporarily_out_of_state: "0", dc_status: true)).to eq true
      end

      it "should return false if there is a change in address from dc to non-dc" do
        consumer_role.verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first.update_attributes(validation_status: "verified")
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "1", is_temporarily_out_of_state: "0", dc_status: false)).to eq false
      end

      it "should return false if there is a change in address from dc to dc" do
        consumer_role.verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first.update_attributes(validation_status: "verified")
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "0", is_temporarily_out_of_state: "0", dc_status: false)).to eq false
      end

      it "should return false if there is a change in address from non-dc to non-dc" do
        consumer_role.verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first.update_attributes(validation_status: "verified")
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "0", is_temporarily_out_of_state: "1", dc_status: true)).to eq false
      end
    end

    context "when has an active coverage & address change from non-dc to dc", dbclean: :after_each do

      before do
        allow(family).to receive(:person_has_an_active_enrollment?).and_return true
      end

      it "should return true if age > 18" do
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "0", is_temporarily_out_of_state: "0", dc_status: true)).to eq true
      end

      it "should return false if age = 18" do
        person.update_attributes(dob: TimeKeeper.date_of_record - 18.years)
        consumer_role.verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first.update_attributes(validation_status: "verified")
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "0", is_temporarily_out_of_state: "0", dc_status: true)).to eq false
      end

      it "should return false if age < 18" do
        consumer_role.person.update_attributes(dob: TimeKeeper.date_of_record - 15.years)
        consumer_role.verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first.update_attributes(validation_status: "verified")
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "0", is_temporarily_out_of_state: "0", dc_status: true)).to eq false
      end
    end

    context "when age > 18 & address change from non-dc to dc" do
      before do
        allow(family).to receive_message_chain(:active_household, :hbx_enrollments, :where).and_return [enrollment]
      end

      it "should return true if has an active coverage" do
        allow(enrollment).to receive_message_chain(:hbx_enrollment_members, :family_member, :person).and_return [consumer_role.person]
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "0", is_temporarily_out_of_state: "0", dc_status: true)).to eq true
      end

      it "should return false if no active coverage" do
        consumer_role.verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first.update_attributes(validation_status: "verified")
        allow(enrollment).to receive_message_chain(:hbx_enrollment_members, :family_member, :person).and_return [nil]
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "0", is_temporarily_out_of_state: "0", dc_status: true)).to eq false
      end
    end

    context "when age > 18 & address change from non-dc to dc & residency status" do
      before do
        allow(family).to receive_message_chain(:active_household, :hbx_enrollments, :where).and_return [enrollment]
      end

      it "should return true if residency status is unverified" do
        allow(enrollment).to receive_message_chain(:hbx_enrollment_members, :family_member, :person).and_return [consumer_role.person]
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "1", is_temporarily_out_of_state: "0", dc_status: true)).to eq true
      end

      it "should return false if residency status is not unverified" do
        consumer_role.verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first.update_attributes(validation_status: "outstanding")
        allow(enrollment).to receive_message_chain(:hbx_enrollment_members, :family_member, :person).and_return [nil]
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "0", is_temporarily_out_of_state: "0", dc_status: true)).to eq false
      end

      it "should return true if residency status is not unverified & address change from non-dc to dc" do
        consumer_role.verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first.update_attributes(validation_status: "outstanding")
        allow(enrollment).to receive_message_chain(:hbx_enrollment_members, :family_member, :person).and_return [consumer_role.person]
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "0", is_temporarily_out_of_state: "0", dc_status: true)).to eq true
      end

      it "should return false if residency status is not unverified & address change from non-dc to non-dc" do
        consumer_role.verification_types.by_name(VerificationType::LOCATION_RESIDENCY).first.update_attributes(validation_status: "outstanding")
        allow(enrollment).to receive_message_chain(:hbx_enrollment_members, :family_member, :person).and_return [consumer_role.person]
        expect(consumer_role.can_trigger_residency?(family, is_homeless: "0", is_temporarily_out_of_state: "1", dc_status: true)).to eq false
      end
    end
  end

  RSpec.shared_examples "a consumer role unchanged by ivl_coverage_selected" do |c_state|
    let(:current_state) { c_state }

    describe "in #{c_state} status" do
      it "does not invoke coverage_selected!" do
        expect(subject).not_to receive(:coverage_purchased!)
        subject.ivl_coverage_selected
      end
    end
  end

  describe ConsumerRole, "receiving a notification of ivl_coverage_selected" do
    let(:person) {Person.new}
    subject { ConsumerRole.new(:aasm_state => current_state, :person => person) }
    describe "in unverified status" do
      let(:current_state) { "unverified" }
      it "fires coverage_selected!" do
        expect(subject).to receive(:coverage_purchased!)
        subject.ivl_coverage_selected
      end
    end

    it_behaves_like "a consumer role unchanged by ivl_coverage_selected", :ssa_pending
    it_behaves_like "a consumer role unchanged by ivl_coverage_selected", :dhs_pending
    it_behaves_like "a consumer role unchanged by ivl_coverage_selected", :verification_outstanding
    it_behaves_like "a consumer role unchanged by ivl_coverage_selected", :fully_verified
    it_behaves_like "a consumer role unchanged by ivl_coverage_selected", :verification_period_ended
  end

  describe "#add_type_history_element" do
    let(:person) {FactoryBot.create(:person, :with_consumer_role)}
    let(:attr) do
      { verification_type: 'verification_type',
        action: 'action',
        modifier: 'actor',
        update_reason: 'reason'}
    end

    it "creates verification history record" do
      person.consumer_role.verification_type_history_elements.delete_all
      person.consumer_role.add_type_history_element(attr)
      expect(person.consumer_role.verification_type_history_elements.size).to be > 0
    end
  end

  describe 'Verification Tracker' do
    let(:person) {FactoryBot.create(:person, :with_consumer_role)}
    context 'mongoid history' do
      it 'stores new record with changes' do
        history_tracker_init = HistoryTracker.count
        person.update_attributes(:first_name => 'updated')
        expect(HistoryTracker.count).to be > history_tracker_init
      end
    end

    context 'mongoid history extension' do
      it 'stores action history element' do
        history_action_tracker_init = person.consumer_role.history_action_trackers.count
        person.update_attributes(:first_name => 'first_name updated', :last_name => 'last_name updated')
        person.reload
        expect(person.consumer_role.history_action_trackers.count).to be > history_action_tracker_init
      end

      it 'associates history element with mongoid history record' do
        person.update_attributes(:first_name => 'first_name updated', :last_name => 'last_name updated')
        person.reload
        expect(person.consumer_role.history_action_trackers.last.tracking_record).to be_a(HistoryTracker)
      end
    end
  end

  describe 'coverage_purchased!' do
    let(:person) {FactoryBot.create(:person, :with_consumer_role)}
    let(:consumer) {person.consumer_role}
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.zone.now, :vlp_authority => 'hbx' })}
    let(:start_date) { person.consumer_role.requested_coverage_start_date}


    it 'should trigger call to ssa hub' do
      unless EnrollRegistry.feature_enabled?(:ssa_h3)
        expect_any_instance_of(LawfulPresenceDetermination).to receive(:notify).with('local.enroll.lawful_presence.ssa_verification_request',
                                                                                     {:person => person})
        expect_any_instance_of(LawfulPresenceDetermination).to receive(:notify).with('local.enroll.lawful_presence.vlp_verification_request',
                                                                                     {:coverage_start_date => TimeKeeper.date_of_record, :person => person})
      end
      person.consumer_role.coverage_purchased!
    end

    it 'should trigger call to dhs hub if person is non native and no ssn ' do
      person.update_attributes(ssn: nil)
      person.consumer_role.lawful_presence_determination.update_attributes(citizen_status: nil)
      unless EnrollRegistry.feature_enabled?(:vlp_h92)
        expect_any_instance_of(LawfulPresenceDetermination).to receive(:notify).with('local.enroll.lawful_presence.vlp_verification_request',
                                                                                     {:person => person, :coverage_start_date => start_date})
      end
      person.consumer_role.coverage_purchased!
    end
  end

  describe 'verification_types' do
    context 'types_include_to_notices' do
      let!(:person) { FactoryBot.create(:person, :with_consumer_role) }

      before :each do
        @consumer_role = person.consumer_role
        @verification_type = person.verification_types.first
      end

      context 'uploaded docuemnts exists' do
        before do
          uploaded_doc = VlpDocument.new(title: 'title', creator: 'creator', identifier: 'identifier')
          @verification_type.vlp_documents = [uploaded_doc]
          @verification_type.save!
        end

        it 'should return verification_type if vlp_doc exists' do
          expect(@consumer_role.types_include_to_notices).to include(@verification_type)
        end
      end

      context 'uploaded docuemnts do not exists' do
        it 'should return verification_type if vlp_doc exists' do
          expect(@consumer_role.types_include_to_notices).to include(@verification_type)
        end
      end
    end
  end

  describe 'vlp documents' do
    context 'i551' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid i551 document exists' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)', card_number: 'abc4567890123') }

        it 'should return an object of type VlpDocument' do
          expect(consumer_role.i551).to be_a(::VlpDocument)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.i551.subject)
        end

        it 'should match the card_number' do
          expect(consumer_role.i551.card_number).to eq('abc4567890123')
        end
      end

      context 'invalid i551 document' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.i551).to be_nil
        end
      end
    end

    context 'i571' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid i551 document exists' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-571 (Refugee Travel Document)') }

        it 'should return true' do
          expect(consumer_role.has_i571?).to eq(true)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.vlp_documents.first.subject)
        end

        it 'should match the subject' do
          expect(consumer_role.vlp_documents.first.subject).to eq(vlp_doc.subject)
        end
      end

      context 'invalid i571 document' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)', card_number: 'abc4567890123') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.has_i571?).to eq(false)
        end
      end
    end

    context 'i766' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid i766 document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document,
                           subject: 'I-766 (Employment Authorization Card)',
                           card_number: 'card_number00',
                           receipt_number: 'receipt_numbr')
        end

        it 'should return an object of type VlpDocument' do
          expect(consumer_role.i766).to be_a(::VlpDocument)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.i766.subject)
        end

        it 'should match the card_number' do
          expect(consumer_role.i766.card_number).to eq('card_number00')
        end
      end

      context 'invalid i766 document' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.i766).to be_nil
        end
      end
    end

    context 'foreign_passport_i94' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid foreign_passport_i94 document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document,
                           subject: 'I-94 (Arrival/Departure Record) in Unexpired Foreign Passport',
                           i94_number: '123456789a0',
                           passport_number: 'N000000',
                           expiration_date: TimeKeeper.date_of_record)
        end

        it 'should return an object of type VlpDocument' do
          expect(consumer_role.foreign_passport_i94).to be_a(::VlpDocument)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.foreign_passport_i94.subject)
        end

        it 'should match the card_number' do
          expect(consumer_role.foreign_passport_i94.passport_number).to eq('N000000')
        end

        it 'should match the i94_number' do
          expect(consumer_role.foreign_passport_i94.i94_number).to eq('123456789a0')
        end
      end

      context 'invalid foreign_passport_i94 document' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.foreign_passport_i94).to be_nil
        end
      end
    end

    context 'foreign_passport' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid foreign_passport document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document,
                           subject: 'Unexpired Foreign Passport',
                           passport_number: 'N000000',
                           expiration_date: TimeKeeper.date_of_record)
        end

        it 'should return an object of type VlpDocument' do
          expect(consumer_role.foreign_passport).to be_a(::VlpDocument)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.foreign_passport.subject)
        end

        it 'should match the card_number' do
          expect(consumer_role.foreign_passport.passport_number).to eq('N000000')
        end
      end

      context 'invalid foreign_passport document' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.foreign_passport).to be_nil
        end
      end
    end

    context 'i327' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid i327 document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document, subject: 'I-327 (Reentry Permit)')
        end

        it 'should return true' do
          expect(consumer_role.has_i327?).to eq(true)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.vlp_documents.first.subject)
        end
      end

      context 'valid i327 document does not exist' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.has_i327?).to eq(false)
        end
      end
    end

    context 'Certificate of Citizenship' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid Certificate of Citizenship document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document, subject: 'Certificate of Citizenship', citizenship_number: '1234567')
        end

        it 'should return true' do
          expect(consumer_role.has_cert_of_citizenship?).to eq(true)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.vlp_documents.first.subject)
        end
      end

      context 'valid Certificate of Citizenship document does not exist' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.has_cert_of_citizenship?).to eq(false)
        end
      end
    end

    context 'Naturalization Certificate' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid Naturalization Certificate document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document, subject: 'Naturalization Certificate', naturalization_number: '1234567')
        end

        it 'should return true' do
          expect(consumer_role.has_cert_of_naturalization?).to eq(true)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.vlp_documents.first.subject)
        end
      end

      context 'valid Naturalization Certificate document does not exist' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.has_cert_of_naturalization?).to eq(false)
        end
      end
    end

    context 'Temporary I-551 Stamp (on passport or I-94)' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid Temporary I-551 Stamp (on passport or I-94) document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document, subject: 'Temporary I-551 Stamp (on passport or I-94)')
        end

        it 'should return true' do
          expect(consumer_role.has_temp_i551?).to eq(true)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.vlp_documents.first.subject)
        end
      end

      context 'valid Temporary I-551 Stamp (on passport or I-94) document does not exist' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.has_temp_i551?).to eq(false)
        end
      end
    end

    context 'I-94 (Arrival/Departure Record)' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid I-94 (Arrival/Departure Record) document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document, subject: 'I-94 (Arrival/Departure Record)', i94_number: '123456789a0')
        end

        it 'should return true' do
          expect(consumer_role.has_i94?).to eq(true)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.vlp_documents.first.subject)
        end
      end

      context 'valid I-94 (Arrival/Departure Record) document does not exist' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.has_i94?).to eq(false)
        end
      end
    end

    context 'I-94 (Arrival/Departure Record) in Unexpired Foreign Passport' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid I-94 (Arrival/Departure Record) in Unexpired Foreign Passport document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document,
                           subject: 'I-94 (Arrival/Departure Record) in Unexpired Foreign Passport',
                           i94_number: '123456789a0',
                           passport_number: 'N000000',
                           expiration_date: TimeKeeper.date_of_record)
        end

        it 'should return true' do
          expect(consumer_role.has_i94?).to eq(true)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.vlp_documents.first.subject)
        end
      end

      context 'valid I-94 (Arrival/Departure Record) in Unexpired Foreign Passport document does not exist' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.has_i94?).to eq(false)
        end
      end
    end

    context 'I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status) document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document,
                           subject: 'I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)',
                           sevis_id: '1234567890')
        end

        it 'should return true' do
          expect(consumer_role.has_i20?).to eq(true)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.vlp_documents.first.subject)
        end
      end

      context 'valid I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status) document does not exist' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.has_i20?).to eq(false)
        end
      end
    end

    context 'DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status) document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document,
                           subject: 'DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)',
                           sevis_id: '1234567890')
        end

        it 'should return true' do
          expect(consumer_role.has_ds2019?).to eq(true)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.vlp_documents.first.subject)
        end
      end

      context 'valid DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status) document does not exist' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.has_ds2019?).to eq(false)
        end
      end
    end

    context 'Machine Readable Immigrant Visa (with Temporary I-551 Language)' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid Machine Readable Immigrant Visa (with Temporary I-551 Language) document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document,
                           subject: 'Machine Readable Immigrant Visa (with Temporary I-551 Language)',
                           passport_number: 'N000000')
        end

        it 'should return an object of type VlpDocument' do
          expect(consumer_role.mac_read_i551).to be_a(::VlpDocument)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.mac_read_i551.subject)
        end
      end

      context 'invalid Machine Readable Immigrant Visa (with Temporary I-551 Language) document' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.mac_read_i551).to be_nil
        end
      end
    end

    context 'Other (With Alien Number)' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid Other (With Alien Number) document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document,
                           subject: 'Other (With Alien Number)',
                           description: 'document description')
        end

        it 'should return an object of type VlpDocument' do
          expect(consumer_role.case1).to be_a(::VlpDocument)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.case1.subject)
        end
      end

      context 'invalid Other (With Alien Number) document' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.case1).to be_nil
        end
      end
    end

    context 'Other (With I-94 Number)' do
      let!(:consumer_role) { FactoryBot.create(:consumer_role, vlp_documents: [vlp_doc]) }

      context 'valid Other (With I-94 Number) document exists' do
        let(:vlp_doc) do
          FactoryBot.build(:vlp_document,
                           subject: 'Other (With I-94 Number)',
                           description: 'document description',
                           i94_number: '123456789i0')
        end

        it 'should return an object of type VlpDocument' do
          expect(consumer_role.case2).to be_a(::VlpDocument)
        end

        it 'should return the subject' do
          expect(::VlpDocument::VLP_DOCUMENT_KINDS).to include(consumer_role.case2.subject)
        end
      end

      context 'invalid Other (With I-94 Number) document' do
        let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'I-551 (Permanent Resident Card)') }

        it 'should not return any object of type VlpDocument' do
          expect(consumer_role.case2).to be_nil
        end
      end
    end

    context 'mark_residency_authorized' do
      let(:person1000) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }

      context 'self_attest_residency' do
        before :each do
          @consumer_role = person1000.consumer_role
          @consumer_role.mark_residency_authorized(OpenStruct.new(self_attest_residency: true))
        end

        it 'should attest local residency type' do
          expect(person1000.verification_type_by_name(VerificationType::LOCATION_RESIDENCY).validation_status).to eq('attested')
        end
      end

      context 'verified local residency' do
        before :each do
          person1000.consumer_role.mark_residency_authorized
        end

        it 'should attest local residency type' do
          expect(person1000.verification_type_by_name(VerificationType::LOCATION_RESIDENCY).validation_status).to eq('verified')
        end
      end
    end

    context 'workflow_state_transitions' do
      let(:person100) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }

      before do
        @consumer_role = person100.consumer_role
        @consumer_role.record_transition(OpenStruct.new(self_attest_residency: true))
      end

      it 'should add reason to newly created workflow_state_transition' do
        expect(@consumer_role.workflow_state_transitions.last.reason).to eq("Self Attest #{VerificationType::LOCATION_RESIDENCY}")
      end
    end

    describe 'admin_verification_action' do
      let!(:consumer) { FactoryBot.create(:person, :with_consumer_role) }
      let!(:verification_type) do
        consumer.verification_types.create!(type_name: 'Citizenship', validation_status: 'unverified')
      end

      before do
        consumer.consumer_role.admin_verification_action('return_for_deficiency', verification_type, 'Illegible')
      end

      xit "should update verification_type" do
        expect(verification_type.validation_status).to eq('rejected')
        expect(verification_type.update_reason).to eq('Illegible')
        expect(verification_type.rejected).to eq(true)
      end
    end

    describe '#admin_ridp_verification_action' do
      let(:person) { FactoryBot.create(:person, :with_consumer_role) }
      let(:consumer_role) { person.consumer_role }

      context 'when admin verifies' do

        it 'returns verified message' do
          expect(consumer_role.admin_ridp_verification_action('verify', 'Identity', 'Document in EnrollApp', person)).to eq 'Identity successfully verified.'
        end
      end

      context 'when admin verifies and consumer has ridp documents' do

        before do
          allow(EnrollRegistry[:show_people_with_no_evidence].feature).to receive(:is_enabled).and_return(false)
        end

        it "should delete the ridp documents" do
          expect(consumer_role.ridp_documents.where(ridp_verification_type: 'Identity').present?).to be_truthy
          consumer_role.admin_ridp_verification_action('verify', 'Identity', 'Document in EnrollApp', person)
          expect(consumer_role.ridp_documents.where(ridp_verification_type: 'Identity').present?).to be_falsey
        end
      end

      context 'when admin rejects' do

        it 'returns rejected message' do
          expect(consumer_role.admin_ridp_verification_action('return_for_deficiency', 'Identity', 'Other', person)).to eq 'Identity successfully rejected.'
        end
      end

      context 'when admin rejects and consumer has ridp documents' do

        before do
          allow(EnrollRegistry[:show_people_with_no_evidence].feature).to receive(:is_enabled).and_return(false)
        end

        it "should delete the ridp documents" do
          expect(consumer_role.ridp_documents.where(ridp_verification_type: 'Identity').present?).to be_truthy
          consumer_role.admin_ridp_verification_action('return_for_deficiency', 'Identity', 'Other', person)
          expect(consumer_role.ridp_documents.where(ridp_verification_type: 'Identity').present?).to be_falsey
        end
      end
    end

    describe 'return_doc_for_deficiency' do
      let!(:consumer) { FactoryBot.create(:person, :with_consumer_role) }

      before do
        consumer.consumer_role.return_doc_for_deficiency(verification_type, 'Illegible')
      end

      context 'for Citizenship' do
        let(:verification_type) do
          consumer.verification_types.create!(type_name: 'Citizenship', validation_status: 'unverified')
        end

        it "should update verification_type" do
          expect(verification_type.validation_status).to eq('rejected')
          expect(verification_type.update_reason).to eq('Illegible')
          expect(verification_type.rejected).to eq(true)
        end
      end

      context 'for Immigration status' do
        let(:verification_type) do
          consumer.verification_types.create!(type_name: 'Immigration status', validation_status: 'unverified')
        end

        it "should update verification_type" do
          expect(verification_type.validation_status).to eq('rejected')
          expect(verification_type.update_reason).to eq('Illegible')
          expect(verification_type.rejected).to eq(true)
        end
      end

      context 'for Social Security Number' do
        let(:verification_type) do
          consumer.verification_types.create!(type_name: 'Social Security Number', validation_status: 'unverified')
        end

        it "should update verification_type" do
          expect(verification_type.validation_status).to eq('rejected')
          expect(verification_type.update_reason).to eq('Illegible')
          expect(verification_type.rejected).to eq(true)
        end
      end

      context 'for Residency' do
        let(:verification_type) do
          consumer.verification_types.create!(type_name: VerificationType::LOCATION_RESIDENCY, validation_status: 'unverified')
        end

        it "should update verification_type" do
          expect(verification_type.validation_status).to eq('rejected')
          expect(verification_type.update_reason).to eq('Illegible')
          expect(verification_type.rejected).to eq(true)
        end
      end
    end
  end

  describe '.create_or_term_eligibility' do

    context 'family members with consumer roles present' do
      let!(:hbx_profile) {FactoryBot.create(:hbx_profile)}
      let!(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
      let!(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
      let(:catalog_eligibility) do
        Operations::Eligible::CreateCatalogEligibility.new.call(
          {
            subject: benefit_coverage_period.to_global_id,
            eligibility_feature: "aca_ivl_osse_eligibility",
            effective_date: benefit_coverage_period.start_on.to_date,
            domain_model: "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
          }
        )
      end
      let(:primary) { FactoryBot.create(:person, :with_consumer_role) }
      let(:spouse) { FactoryBot.create(:person, :with_consumer_role) }
      let(:child1) { FactoryBot.create(:person, :with_consumer_role) }

      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: primary)}
      let!(:family_member_spouse) { FactoryBot.create(:family_member, person: spouse, family: family)}
      let!(:family_member_child1) { FactoryBot.create(:family_member, person: child1, family: family)}

      let(:osse_eligible_members) { [primary, child1] }

      context 'it should create eligibility for active family members' do
        let(:valid_params) do
          {
            evidence_key: :ivl_osse_evidence,
            evidence_value: 'true',
            effective_date: TimeKeeper.date_of_record.beginning_of_year
          }
        end

        before do
          allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
          catalog_eligibility
          osse_eligible_members.each do |person|
            person.consumer_role.create_or_term_eligibility(valid_params)
            person.consumer_role.reload
          end
        end

        def verify_active_family_members
          family.active_family_members.each do |fm|
            next if osse_eligible_members.exclude?(fm.person)
            consumer_role = fm.person.consumer_role
            yield(consumer_role)
          end
        end

        it 'should create eligibility for primary and child only' do
          expect(primary.consumer_role.eligibilities).to be_present
          expect(spouse.consumer_role.eligibilities).to be_blank
          expect(child1.consumer_role.eligibilities).to be_present
        end

        it 'should create eligibility with given effective date' do
          verify_active_family_members do |consumer_role|
            expect(consumer_role.eligibilities.count).to eq 1
            expect(consumer_role.eligibilities.first.effective_on).to eq valid_params[:effective_date]
          end
        end

        it 'should create eligibility with evidence' do
          verify_active_family_members do |consumer_role|
            eligibility = consumer_role.eligibilities.first
            expect(eligibility.evidences.by_key(valid_params[:evidence_key]).count).to eq 1
            expect(eligibility.evidences.by_key(valid_params[:evidence_key]).first.is_satisfied.to_s).to eq valid_params[:evidence_value]
          end
        end
      end

      context 'it should term eligibility' do
        let(:consumer_role) { primary.consumer_role }
        let!(:ivl_osse_eligibility) do
          eligibility = build(:ivl_osse_eligibility,
                              :with_admin_attested_evidence,
                              :evidence_state => :approved,
                              :is_eligible => false)
          consumer_role.eligibilities << eligibility
          consumer_role.save!
          eligibility
        end

        let(:valid_params) do
          {
            evidence_key: :ivl_osse_evidence,
            evidence_value: 'false',
            effective_date: TimeKeeper.date_of_record
          }
        end

        before { consumer_role.create_or_term_eligibility(valid_params) }
        it { expect(consumer_role.reload.osse_eligible?(TimeKeeper.date_of_record)).to be_falsey }
      end
    end
  end

  describe 'create default osse eligibility on create' do
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile)}
    let!(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
    let!(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
    let(:catalog_eligibility) do
      Operations::Eligible::CreateCatalogEligibility.new.call(
        {
          subject: benefit_coverage_period.to_global_id,
          eligibility_feature: "aca_ivl_osse_eligibility",
          effective_date: benefit_coverage_period.start_on.to_date,
          domain_model: "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
        }
      )
    end
    let(:consumer_role) { FactoryBot.build(:consumer_role) }
    let(:current_year) { TimeKeeper.date_of_record.year }

    context 'when osse feature for the given year is disabled' do
      before do
        EnrollRegistry["aca_ivl_osse_eligibility_#{current_year}"].feature.stub(:is_enabled).and_return(false)
        catalog_eligibility
      end

      it 'should create osse eligibility in initial state' do
        expect(consumer_role.eligibilities.count).to eq 0
        consumer_role.save
        expect(consumer_role.reload.eligibilities.count).to eq 0
      end
    end

    context 'when osse feature for the given year is enabled' do
      before do
        allow(EnrollRegistry).to receive(:feature?).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
        catalog_eligibility
      end

      it 'should create osse eligibility in initial state' do
        expect(consumer_role.eligibilities.count).to eq 0
        consumer_role.save!
        expect(consumer_role.reload.eligibilities.count).to eq 1
        eligibility = consumer_role.eligibilities.first
        expect(eligibility.key).to eq "aca_ivl_osse_eligibility_#{TimeKeeper.date_of_record.year}".to_sym
        expect(eligibility.current_state).to eq :ineligible
        expect(eligibility.state_histories.count).to eq 1
        expect(eligibility.evidences.count).to eq 1
        evidence = eligibility.evidences.first
        expect(evidence.key).to eq :ivl_osse_evidence
        expect(evidence.current_state).to eq :not_approved
        expect(evidence.state_histories.count).to eq 1
      end
    end
  end

  describe '#update_by_person' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:consumer_role) { person.consumer_role }
    let(:params) do
      {"skip_person_updated_event_callback" => true, "skip_lawful_presence_determination_callbacks" => true,
       "addresses_attributes" => {"0" => {"kind" => "home", "address_1" => "123", "address_2" => "", "city" => "was", "state" => "ME", "zip" => "04001", "county" => "York", "id" => person.home_address.id.to_s, "_destroy" => "false"}},
       "phones_attributes" => {"0" => {"kind" => "home", "full_phone_number" => "", "_destroy" => "false"}, "1" => {"kind" => "mobile", "full_phone_number" => "", "_destroy" => "false"}},
       "emails_attributes" => {"0" => {"kind" => "home", "address" => "", "_destroy" => "false"}, "1" => {"kind" => "work", "address" => "", "_destroy" => "false"}},
       "consumer_role_attributes" => {"contact_method" => "Only Paper communication", "language_preference" => "English"},
       "first_name" => "ivl576", "last_name" => "576", "middle_name" => "", "name_sfx" => "", "no_ssn" => "0", "gender" => "male", "is_incarcerated" => "false", "is_consumer_role" => "true",
       "ethnicity" => ["", "", "", "", "", "", ""], "us_citizen" => "true", "naturalized_citizen" => "false", "eligible_immigration_status" => "false", "indian_tribe_member" => "false",
       "tribal_state" => "", "tribal_name" => "", "tribe_codes" => [""], "is_homeless" => "0", "dob_check" => "false"}
    end

    it "should assign skip_lawful_presence_determination_callbacks value" do
      consumer_role.update_by_person(params)
      expect(consumer_role.lawful_presence_determination.skip_lawful_presence_determination_callbacks).to eq true
    end

    it "should not assign skip_lawful_presence_determination_callbacks value" do
      consumer_role.update_by_person(params.except("skip_lawful_presence_determination_callbacks"))
      expect(consumer_role.lawful_presence_determination.skip_lawful_presence_determination_callbacks).to eq nil
    end

    it "should not assign skip_lawful_presence_determination_callbacks value for false" do
      consumer_role.update_by_person(params.merge("skip_lawful_presence_determination_callbacks" => false))
      expect(consumer_role.lawful_presence_determination.skip_lawful_presence_determination_callbacks).to eq nil
    end
  end
end

class VlpDocument
  VLP_DOCUMENT_KINDS = ["I-327 (Reentry Permit)", "I-551 (Permanent Resident Card)", "I-571 (Refugee Travel Document)", "I-766 (Employment Authorization Card)",
                        "Certificate of Citizenship","Naturalization Certificate","Machine Readable Immigrant Visa (with Temporary I-551 Language)", "Temporary I-551 Stamp (on passport or I-94)", "I-94 (Arrival/Departure Record)",
                        "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport", "Unexpired Foreign Passport",
                        "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)", "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)",
                        "Other (With Alien Number)", "Other (With I-94 Number)"].freeze
end

# rubocop:enable Metrics/ParameterLists
