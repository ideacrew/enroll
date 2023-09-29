# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Fdsh::PayloadEligibility::CheckPersonEligibilityRules do
  describe 'request_type ssa' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:payload_entity) do
      value = Operations::Transformers::PersonTo::Cv3Person.new.call(person).success
      AcaEntities::People::Person.new(value.to_h)
    end
    let(:request_type) { :ssa }
    let(:validator) { instance_double(Operations::Fdsh::EncryptedSsnValidator) }

    context 'when all validation rules pass' do
      it 'returns a Success result' do
        result = described_class.new.call(payload_entity, request_type)
        expect(result).to be_success
      end
    end

    context 'when a validation rule fails' do
      before do
        allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
        allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
      end

      it 'returns a Failure result' do
        result = described_class.new.call(payload_entity, request_type)
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.new.call(payload_entity, request_type)
        expect(result.failure).to eq(["Invalid SSN"])
      end
    end

    context 'person without SSN' do
      let(:person) do
        per = FactoryBot.create(:person, :with_consumer_role)
        per.update_attributes!(encrypted_ssn: nil)
        per
      end

      it 'returns a failure result with an error message' do
        expect(
          subject.call(payload_entity, request_type).failure
        ).to include('No SSN')
      end
    end
  end

  describe 'request_type dhs' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:person_payload) {Operations::Transformers::PersonTo::Cv3Person.new.call(person).success}
    let(:person_entity) { AcaEntities::People::Person.new(person_payload.to_h)}
    let(:request_type) { :dhs }
    let(:validator) { instance_double(Operations::Fdsh::EncryptedSsnValidator) }

    context 'when all validation rules pass' do
      it 'returns a Success result' do
        result = described_class.new.call(person_entity, request_type)
        expect(result).to be_success
      end
    end

    context 'when a ssn validation rule is not present' do
      before do
        allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
        allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
      end

      it 'returns a Success' do
        result = described_class.new.call(person_entity, request_type)
        expect(result).to be_success
      end
    end

    context 'when a no vlp documents exists for a consumer' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role].merge!(vlp_documents: [])
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      it 'returns a Success' do
        result = described_class.new.call(person_entity, request_type)
        expect(result.failure).to include('No VLP Documents')
      end
    end

    context 'when document type I-327 (Reentry Permit) has missing alien_number' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!(alien_number: nil)
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns failure' do
        expect(@result).to be_failure
      end

      it 'returns an error message' do
        expect(@result.failure).to eq(["Missing/Invalid information on vlp document"])
      end
    end

    context 'subject: I-327 (Reentry Permit)' do

      context 'when given a valid document entity' do
        let(:person_entity) do
          person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({:subject => 'I-327 (Reentry Permit)',:alien_number => '123456789'})
          AcaEntities::People::Person.new(person_payload.to_h)
        end

        before do
          @result = described_class.new.call(person_entity, request_type)
        end

        it 'returns a success result' do
          expect(@result).to be_success
        end
      end

      context 'when given an invalid document entity' do
        let(:person_entity) do
          person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({:subject => 'I-327 (Reentry Permit)',:alien_number => nil})
          AcaEntities::People::Person.new(person_payload.to_h)
        end

        before do
          @result = described_class.new.call(person_entity, request_type)
        end

        it 'returns a failure result' do
          expect(@result).to be_failure
        end

        it 'returns an error message' do
          expect(@result.failure).to eq(['Missing/Invalid information on vlp document'])
        end
      end
    end

    context 'subject: I-766 (Employment Authorization Card)' do
      context 'when given a valid document entity' do
        let(:consumer_role) { FactoryBot.create(:consumer_role, person: person) }
        let(:person) { FactoryBot.create(:person) }
        let(:vlp_document) { FactoryBot.create(:vlp_document, :i766, documentable: consumer_role) }

        before do
          vlp_document
          @result = described_class.new.call(person_entity, request_type)
        end

        it 'returns a success' do
          expect(@result).to be_success
        end
      end

      context 'when given an invalid document entity' do
        let(:person_entity) do
          person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                          :subject => 'I-766 (Employment Authorization Card)',
                                                                          :alien_number => nil,
                                                                          :card_number => '1234567891234'
                                                                        })
          AcaEntities::People::Person.new(person_payload.to_h)
        end

        before do
          @result = described_class.new.call(person_entity, request_type)
        end

        it 'returns a failure' do
          expect(@result).to be_failure
        end

        it 'returns an error message' do
          expect(@result.failure).to eq(['Missing/Invalid information on vlp document'])
        end
      end
    end

    context 'when given a Certificate of Citizenship document entity' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({:subject => 'Certificate of Citizenship', :citizenship_number => '123456789'})
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a success' do
        expect(@result).to be_success
      end
    end

    context 'when given a Naturalization Certificate document entity' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                        :subject => 'Naturalization Certificate',
                                                                        :naturalization_number => '123456789'
                                                                      })
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a success' do
        expect(@result).to be_success
      end
    end

    context 'when given a Machine Readable Immigrant Visa document entity' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                        :subject => 'Machine Readable Immigrant Visa (with Temporary I-551 Language)',
                                                                        :alien_number => '123456789',
                                                                        :passport_number => '987654321',
                                                                        :country_of_citizenship => 'USA'
                                                                      })
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a success result' do
        expect(@result).to be_success
      end
    end

    context 'when given a Temporary I-551 Stamp document entity' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                        :subject => 'Temporary I-551 Stamp (on passport or I-94)',
                                                                        :alien_number => '123456789'
                                                                      })
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a success' do
        expect(@result).to be_success
      end
    end

    context 'when given an I-94 document entity' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                        :subject => 'I-94 (Arrival/Departure Record)',
                                                                        :i94_number => '12345678932'
                                                                      })
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a success' do
        expect(@result).to be_success
      end
    end

    context 'when given an I-94 in Unexpired Foreign Passport document entity' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                        :subject => 'I-94 (Arrival/Departure Record) in Unexpired Foreign Passport',
                                                                        :i94_number => '12345678932',
                                                                        :passport_number => '987654321',
                                                                        :country_of_citizenship => 'USA',
                                                                        :expiration_date => DateTime.now + 90.days
                                                                      })
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a success' do
        expect(@result).to be_success
      end
    end

    context 'when given an Unexpired Foreign Passport document entity' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                        :subject => 'Unexpired Foreign Passport',
                                                                        :passport_number => '987654321',
                                                                        :country_of_citizenship => 'USA',
                                                                        :expiration_date => DateTime.now + 90.days
                                                                      })
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a success' do
        expect(@result).to be_success
      end
    end

    context 'when given an I-20 document entity' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                        :subject => 'I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)',
                                                                        :sevis_id => '1234567891'
                                                                      })
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a success' do
        expect(@result).to be_success
      end
    end

    context 'when given a DS2019 document entity' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                        :subject => 'DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)',
                                                                        :sevis_id => '1234567891'
                                                                      })
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a success' do
        expect(@result).to be_success
      end
    end

    context 'when given an Other (With Alien Number) document entity' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                        :subject => 'Other (With Alien Number)',
                                                                        :alien_number => '123456789',
                                                                        :description => 'Test 1234'
                                                                      })
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a success' do
        expect(@result).to be_success
      end
    end

    context 'when given an Other (With I-94 Number) document entity' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                        :subject => 'Other (With I-94 Number)',
                                                                        :i94_number => '12345678912',
                                                                        :description => 'Test 1234'
                                                                      })
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a success' do
        expect(@result).to be_success
      end
    end

    context 'when given an invalid document type' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                        :subject => 'Test 1234',
                                                                        :i94_number => '123456789'
                                                                      })
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a failure' do
        expect(@result).to be_failure
      end
    end

    context 'when given an invalid I-551 type' do
      let(:person_entity) do
        person_payload.to_h[:consumer_role][:vlp_documents][0].merge!({
                                                                        :subject => 'I551 1234',
                                                                        :card_number => '123456789'
                                                                      })
        AcaEntities::People::Person.new(person_payload.to_h)
      end

      before do
        @result = described_class.new.call(person_entity, request_type)
      end

      it 'returns a failure' do
        expect(@result).to be_failure
      end
    end
  end
end
