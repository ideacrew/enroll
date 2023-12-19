# frozen_string_literal: true

require 'rails_helper'
require 'domain/operations/financial_assistance/applicant_params_context'

RSpec.describe Operations::People::InitializePerson do
  describe '#call' do
    include_context 'export_applicant_attributes_context'

    let(:params) do
      applicant_params.merge(family_id: family.id, relationship: 'child')
    end

    context 'success' do
      before do
        @result = described_class.new.call(applicant_params)
      end

      it 'returns a success result' do
        expect(@result.success?).to be_truthy
      end

      it 'returns a person hash' do
        expect(@result.success).to be_a(Entities::Person)
      end

      it 'returns a hash with person attributes' do
        hash = @result.success.to_h
        expect(hash).to have_key(:addresses)
        expect(hash).to have_key(:phones)
        expect(hash).to have_key(:emails)
        expect(hash).to have_key(:hbx_id)
        expect(hash).not_to have_key(:person_hbx_id)
      end

      it 'returns a hash without consumer role attributes' do
        hash = @result.success.to_h
        expect(hash).not_to have_key(:consumer_role)
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
          expect(@result.failure.errors.to_h).to eq({:dob => ["is missing", "must be a date"], :first_name => ["is missing", "must be a string"], :gender => ["is missing", "must be a string"], :last_name => ["is missing", "must be a string"]})
        end
      end
    end
  end
end