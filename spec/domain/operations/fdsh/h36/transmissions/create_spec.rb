# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Fdsh::H36::Transmissions::Create do
  subject { described_class.new.call(input_params) }

  context 'with valid params' do
    let(:input_params) { { assistance_year:  Date.today.year, month_of_year: Date.today.month } }

    it 'returns success with message' do
      expect(subject.success).to eq(
        'Successfully published payload with event: events.h36.transmission_requested'
      )
    end
  end

  context 'with invalid params' do
    context 'missing params' do
      let(:input_params) { {} }

      it 'returns failure with message' do
        expect(subject.failure).to eq(
          ['assistance_year must be a valid Integer', 'month_of_year must be a valid Integer']
        )
      end
    end

    context 'invalid data types for arguments' do
      let(:input_params) { { assistance_year:  'assistance_year', month_of_year: 'month_of_year' } }

      it 'returns failure with message' do
        expect(subject.failure).to eq(
          ['assistance_year must be a valid Integer', 'month_of_year must be a valid Integer']
        )
      end
    end
  end
end
