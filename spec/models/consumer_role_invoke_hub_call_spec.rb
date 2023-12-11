# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'

describe ConsumerRole, dbclean: :around_each do
  before { DatabaseCleaner.clean }
  describe '#eligible_for_invoking_dhs?' do
    let(:person) { FactoryBot.create(:person, :with_ssn) }
    let(:consumer_role) do
      FactoryBot.create(
        :consumer_role,
        is_applying_coverage: is_applying_coverage,
        person: person,
        lawful_presence_determination: lawful_presence_determination
      )
    end
    let(:lawful_presence_determination) { FactoryBot.build(:lawful_presence_determination, citizen_status: citizen_status) }

    shared_examples_for 'eligibility of invoking dhs call' do |citizen_status, is_applying_coverage, eligible|
      let(:citizen_status) { citizen_status }
      let(:is_applying_coverage) { is_applying_coverage }

      it "returns #{eligible} for citizen_status: #{citizen_status} and member attestation #{is_applying_coverage} to coverage required" do
        expect(consumer_role.eligible_for_invoking_dhs?).to eq(eligible)
      end
    end

    context 'with different citizen status and consumer applying for coverage' do
      it_behaves_like 'eligibility of invoking dhs call', 'alien_lawfully_present', true, true
      it_behaves_like 'eligibility of invoking dhs call', 'lawful_permanent_resident', true, false
      it_behaves_like 'eligibility of invoking dhs call', 'naturalized_citizen', true, true
      it_behaves_like 'eligibility of invoking dhs call', 'non_native_not_lawfully_present_in_us', true, true
      it_behaves_like 'eligibility of invoking dhs call', 'not_lawfully_present_in_us', true, true
      it_behaves_like 'eligibility of invoking dhs call', 'us_citizen', true, false
    end

    context 'with different citizen status and consumer not applying for coverage' do
      it_behaves_like 'eligibility of invoking dhs call', 'alien_lawfully_present', false, false
      it_behaves_like 'eligibility of invoking dhs call', 'lawful_permanent_resident', false, false
      it_behaves_like 'eligibility of invoking dhs call', 'naturalized_citizen', false, false
      it_behaves_like 'eligibility of invoking dhs call', 'non_native_not_lawfully_present_in_us', false, false
      it_behaves_like 'eligibility of invoking dhs call', 'not_lawfully_present_in_us', false, false
      it_behaves_like 'eligibility of invoking dhs call', 'us_citizen', false, false
    end
  end

  describe 'is_native? and no ssn' do
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.zone.now, :vlp_authority => 'hbx' })}
    let!(:person) { FactoryBot.create(:person, :with_ssn) }
    let!(:consumer_role) do
      FactoryBot.create(
        :consumer_role,
        is_applying_coverage: is_applying_coverage,
        person: person,
        lawful_presence_determination: lawful_presence_determination
      )
    end
    let!(:lawful_presence_determination) { FactoryBot.build(:lawful_presence_determination, citizen_status: citizen_status) }
    let!(:citizen_status) { 'us_citizen' }
    let!(:is_applying_coverage) { true }

    context 'validate_and_record_publish_errors enabled' do
      shared_examples_for 'IVL state machine transitions and verification_types validation_status' do |from_state, to_state, event, type_name, verification_type_validation_status|
        before do
          allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(false)
          allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:ssa_h3).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:vlp_h92).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_errors).and_return(true)

          person.ssn = nil
          person.save!
          consumer_role.reload
        end

        it "moves from #{from_state} to #{to_state} on #{event}" do
          expect(consumer_role).to transition_from(from_state).to(to_state).on_event(event.to_sym, verification_attr)
          citizenship_type = consumer_role.verification_types.where(:type_name.in => type_name).first
          expect(citizenship_type.validation_status).to eq verification_type_validation_status
          expect(citizenship_type.type_history_elements.last.action).to eq "Hub Request Failed"
        end
      end

      context 'coverage_purchased_no_residency with us_citizen and no ssn' do
        it_behaves_like 'IVL state machine transitions and verification_types validation_status', :unverified, :verification_outstanding, 'coverage_purchased_no_residency!', ["Citizenship"], "negative_response_received"
      end
    end

    context 'validate_and_record_publish_errors disabled' do
      shared_examples_for 'IVL state machine transitions and verification_types validation_status' do |from_state, to_state, event, type_name, verification_type_validation_status|
        before do
          allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(false)
          allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:ssa_h3).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:vlp_h92).and_return(true)
          allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_errors).and_return(false)

          person.ssn = nil
          person.save!
          consumer_role.reload
        end

        it "moves from #{from_state} to #{to_state} on #{event}" do
          expect(consumer_role).to transition_from(from_state).to(to_state).on_event(event.to_sym, verification_attr)
          citizenship_type = consumer_role.verification_types.where(:type_name.in => type_name).first
          expect(citizenship_type.validation_status).to eq verification_type_validation_status
          expect(citizenship_type.type_history_elements.present?).to be_falsey
        end
      end

      context 'coverage_purchased_no_residency with us_citizen and no ssn' do
        it_behaves_like 'IVL state machine transitions and verification_types validation_status', :unverified, :verification_outstanding, 'coverage_purchased_no_residency!', ["Citizenship"], "negative_response_received"
      end
    end
  end

  describe '#immigration_documents_attributes=' do
    let(:consumer_role) { FactoryBot.create(:consumer_role) }

    context 'when the VLP document already exists' do
      let(:vlp_document_attributes) { { 'subject' => 'I-327 (Reentry Permit)', 'alien_number' => '111111111' } }
      let(:array_attributes) { [vlp_document_attributes] }

      it 'updates the existing VLP document' do
        vlp_document = consumer_role.vlp_documents.first
        expect do
          consumer_role.immigration_documents_attributes = array_attributes
        end.to change { vlp_document.alien_number }.to("111111111")
      end
    end

    context 'when the VLP document does not exist' do
      let(:vlp_document_attributes) { { 'subject' => 'Test VLP Document', 'expiration_date' => Date.new(2022, 12, 31) } }
      let(:array_attributes) { [vlp_document_attributes] }

      it 'creates a new VLP document' do
        consumer_role.vlp_documents.delete_all

        expect do
          consumer_role.immigration_documents_attributes = array_attributes
        end.to change { consumer_role.vlp_documents.size }.by(1)
        expect(consumer_role.vlp_documents.last.subject).to eq('Test VLP Document')
        expect(consumer_role.vlp_documents.last.expiration_date).to eq(Date.new(2022, 12, 31))
      end
    end
  end
end
