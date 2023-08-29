# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/shared_contexts/valid_cv3_application_setup.rb')

RSpec.describe Operations::Fdsh::EvidenceVerificationRequest, dbclean: :after_each do
  include_context "valid cv3 application setup"

  describe '#call' do
    context 'on applicant income evidence' do
      let(:evidence) { applicant.income_evidence }

      context 'builds and publishes with no errors' do
        let(:updated_by) { 'admin' }
        let(:update_reason) { "Requested Hub for verification" }
        let(:action) { 'request_hub' }

        it 'should return success' do
          current_aasm_state = evidence.aasm_state

          result = evidence.request_determination(action, update_reason, updated_by)
          evidence.reload

          expect(result).to be_truthy
          expect(evidence.aasm_state).to eq(current_aasm_state)
          expect(evidence.verification_histories).to be_present

          history = evidence.verification_histories.first
          expect(history.action).to eq action
          expect(history.update_reason).to eq update_reason
          expect(history.updated_by).to eq updated_by
        end
      end

      context 'builds and publishes with errors' do
        let(:action) { 'Hub Request Failed' }
        let(:updated_by) { 'System' }
        let(:update_reason) { "Income Evidence Verification Request Failed due to [\"Invalid SSN\"]" }

        before do
          applicant.update(ssn: '000238754')
        end

        context 'with an applicant who does not have an active enrollment' do
          it 'should change evidence aasm_state to outstanding' do
            evidence = applicant.income_evidence
            result = evidence.request_determination(action, update_reason, updated_by)
            evidence.reload

            expect(result).to be_falsey
            expect(evidence.aasm_state).to eq('outstanding')
            expect(evidence.verification_histories).to be_present

            history = evidence.verification_histories.first
            expect(history.action).to eq action
            expect(history.update_reason).to eq update_reason
            expect(history.updated_by).to eq updated_by
          end
        end

        context 'with an applicant with active enrollment and aptc' do
          before do
            eligibility_determination.update(max_aptc: 720.0)
          end

          it 'should change evidence aasm_state to negative_response_received' do
            evidence = applicant.income_evidence
            result = evidence.request_determination(action, update_reason, updated_by)
            evidence.reload

            expect(result).to be_falsey
            expect(evidence.aasm_state).to eq('negative_response_received')
            expect(evidence.verification_histories).to be_present

            history = evidence.verification_histories.first
            expect(history.action).to eq action
            expect(history.update_reason).to eq update_reason
            expect(history.updated_by).to eq updated_by
          end
        end

        context 'with an applicant with active enrollment and csr' do
          before do
            applicant.update(csr_percent_as_integer: 73, csr_eligibility_kind: 'csr_73')
          end

          it 'should change evidence aasm_state to negative_response_received' do
            evidence = applicant.income_evidence
            result = evidence.request_determination(action, update_reason, updated_by)
            evidence.reload

            expect(result).to be_falsey
            expect(evidence.aasm_state).to eq('negative_response_received')
            expect(evidence.verification_histories).to be_present

            history = evidence.verification_histories.first
            expect(history.action).to eq action
            expect(history.update_reason).to eq update_reason
            expect(history.updated_by).to eq updated_by
          end
        end
      end
    end
  end
end