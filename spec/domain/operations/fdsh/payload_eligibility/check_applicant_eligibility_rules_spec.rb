# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/shared_contexts/valid_cv3_application_setup.rb')

RSpec.describe Operations::Fdsh::PayloadEligibility::CheckApplicantEligibilityRules, dbclean: :after_each do
  include_context "valid cv3 application setup"

  describe '#call' do
    let(:cv3_application) { ::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application).success }
    let(:payload_entity) { AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(cv3_application).success }
    let(:request_type) { :income }

    context 'when all validation rules pass' do
      it 'returns a Success result' do
        applicant = payload_entity.applicants[0]

        result = described_class.new.call(applicant, request_type)
        expect(result).to be_success
      end
    end

    context 'when a validation rule fails' do
      let(:validator) { instance_double(Operations::Fdsh::EncryptedSsnValidator) }

      before do
        allow(validator).to receive(:call).and_return(Dry::Monads::Failure('Invalid SSN'))
        allow(Operations::Fdsh::EncryptedSsnValidator).to receive(:new).and_return(validator)
      end

      it 'returns a Failure result' do
        applicant = payload_entity.applicants[0]

        result = described_class.new.call(applicant, request_type)
        expect(result).to be_failure
      end

      it 'returns an error message' do
        applicant = payload_entity.applicants[0]

        result = described_class.new.call(applicant, request_type)
        expect(result.failure).to eq(["Invalid SSN"])
      end
    end
  end
end