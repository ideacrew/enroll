# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'default fdsh service namespace client specific configurations' do

  describe 'non_esi_h31' do
    context 'for default value' do
      it 'returns default value xml' do
        expect(EnrollRegistry.feature_enabled?(:non_esi_h31)).to be_truthy
        expect(EnrollRegistry[:non_esi_h31].setting(:payload_format).item).to eq('xml')
      end
    end
  end
end
