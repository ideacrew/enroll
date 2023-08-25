# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Fdsh::PayloadEligibility::CheckApplicationEligibilityRules do
  include Dry::Monads[:result, :do]

  describe 'request_type income' do
    let(:family_id) { BSON::ObjectId.new }
    let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: 'draft') }

    let!(:applicant) do
      FactoryBot.create(:financial_assistance_applicant,
                        :with_work_phone,
                        :with_work_email,
                        :with_home_address,
                        application: application,
                        ssn: '889984400',
                        dob: (Date.today - 10.years),
                        first_name: 'james',
                        last_name: 'bond',
                        is_primary_applicant: true)
    end

    let(:request_type) { :income }
    let(:validator) { instance_double(Operations::Fdsh::EncryptedSsnValidator) }
    let(:payload_entity) do 
      AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call({})
    end

    context 'when all validation rules pass' do
      before do
        binding.irb
        allow(payload_entity).to receive(:applicants).and_return(application.applicants)
        allow(:applicant).to receive(:identifying_information).and_return(self)
      end

      it 'returns a Success result' do
        binding.irb
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
  end
end