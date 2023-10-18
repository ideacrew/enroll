# frozen_string_literal: true

require 'rails_helper'
require 'domain/operations/financial_assistance/applicant_params_context'

RSpec.describe Operations::People::InitializeVlpDocument do
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

      it 'returns a vlp document hash' do
        expect(@result.success).to be_a(Entities::VlpDocument)
      end

      it 'returns a hash without person attributes' do
        hash = @result.success.to_h
        expect(hash).not_to have_key(:person_addresses)
        expect(hash).not_to have_key(:person_phones)
        expect(hash).not_to have_key(:person_emails)
        expect(hash).not_to have_key(:hbx_id)
        expect(hash).not_to have_key(:person_hbx_id)
      end

      it 'returns a hash without consumer role attributes' do
        hash = @result.success.to_h
        expect(hash).not_to have_key(:is_applicant)
        expect(hash).not_to have_key(:is_applying_coverage)
        expect(hash).not_to have_key(:citizen_status)
      end

      it 'returns a hash with vlp document attributes that are filled' do
        hash = @result.success.to_h
        expect(hash).to have_key(:subject)
        expect(hash).to have_key(:i94_number)
        expect(hash).to have_key(:expiration_date)
        expect(hash).not_to have_key(:sevis_id)
      end
    end

    context 'failure' do
      context 'when applicant params are not passed' do
        let(:applicant_params) { {} }

        before do
          @result = described_class.new.call(applicant_params)
        end

        it 'returns a success result' do
          expect(@result.success?).to be_truthy
        end

        it 'should not return failure message' do
          expect(@result.success.to_h).to eq({})
        end
      end
    end
  end
end