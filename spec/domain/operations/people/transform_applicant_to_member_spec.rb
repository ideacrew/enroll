# frozen_string_literal: true

require 'rails_helper'
require 'domain/operations/financial_assistance/applicant_params_context'

RSpec.describe Operations::People::TransformApplicantToMember do
  include_context 'export_applicant_attributes_context'

  describe '#call' do
    let(:params) do
      applicant_params.merge(family_id: family.id, relationship: 'spouse')
    end

    context 'success' do
      before do
        @result = described_class.new.call(params)
      end

      it 'returns a success result' do
        expect(@result.success?).to be_truthy
      end

      it 'returns a member hash' do
        expect(@result.success).to be_a(Hash)
      end

      it 'returns a member hash with person attributes' do
        member_hash = @result.success
        expect(member_hash).to have_key(:person_addresses)
        expect(member_hash).to have_key(:person_phones)
        expect(member_hash).to have_key(:person_emails)
        expect(member_hash).to have_key(:hbx_id)
        expect(member_hash).not_to have_key(:person_hbx_id)
      end

      it 'returns a member hash with consumer role attributes' do
        member_hash = @result.success
        expect(member_hash).to have_key(:consumer_role)
        expect(member_hash[:consumer_role]).to have_key(:skip_consumer_role_callbacks)
        expect(member_hash[:consumer_role]).to have_key(:is_applicant)
        expect(member_hash[:consumer_role]).to have_key(:vlp_documents_attributes)
      end
    end

    context 'failure' do
      context 'when applicant params are not passed' do
        let(:applicant_params) { {} }

        before do
          @result = described_class.new.call(applicant_params)
        end

        it 'returns a failure result' do
          expect(@result.failure?).to be_truthy
        end

        it 'returns a failure message' do
          expect(@result.failure).to eq('Provide applicant_params for transformation')
        end
      end
    end
  end
end