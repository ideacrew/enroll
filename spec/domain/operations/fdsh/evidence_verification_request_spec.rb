# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/shared_contexts/valid_cv3_application_setup.rb')

RSpec.describe Operations::Fdsh::EvidenceVerificationRequest, dbclean: :after_each do
  include_context "valid cv3 application setup"

  describe '#call' do
    context 'on applicant income evidence' do
      let(:evidence) { applicant.income_evidence }

      context 'builds and publishes with no errors' do
        it 'should return success' do
          current_aasm_state = evidence.aasm_state
          result = described_class.new.call(evidence).success
          evidence.reload

          expect(result).to eq("Event published successfully")
          expect(evidence.aasm_state).to eq(current_aasm_state)
        end
      end

      context 'builds and publishes with errors' do
        let(:build_and_validate_payload_entity) { instance_double(Operations::Fdsh::BuildAndValidateApplicationPayload) }
        let(:error_reponse) { 'Could not generate CV3 Application Object' }

        let(:action) { 'Hub Request Failed' }
        let(:updated_by) { 'System' }
        let(:update_reason) { "Income Evidence Verification Request Failed due to [\"Invalid SSN\"]" }

        before do
          allow(build_and_validate_payload_entity).to receive(:call).and_return(Dry::Monads::Failure(error_reponse))
          allow(Operations::Fdsh::BuildAndValidateApplicationPayload).to receive(:new).and_return(build_and_validate_payload_entity)
        end

        it 'should return an error and not update evidence aasm_state' do
          evidence = applicant.income_evidence
          current_aasm_state = evidence.aasm_state
          result = described_class.new.call(evidence)
          evidence.reload

          expect(result).to be_failure
          expect(result.failure).to eq(error_reponse)
          expect(evidence.aasm_state).to eq(current_aasm_state)
        end
      end
    end
  end
end