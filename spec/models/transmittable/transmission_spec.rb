# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transmittable::Transmission, type: :model, dbclean: :after_each do
  let(:transmission) { FactoryBot.create(:transmittable_transmission) }

  describe '#to_global_id' do
    it 'responds to to_global_id' do
      expect(transmission.respond_to?(:to_global_id)).to be_truthy
    end

    it 'returns the GlobalID URI' do
      expect(
        transmission.to_global_id.uri.to_s
      ).to eq("gid://enroll/#{described_class}/#{transmission.id}")
    end
  end
end
