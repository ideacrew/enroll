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

  describe '#transactions' do
    context 'when there are no transactions' do
      it 'does not return any transactions' do
        expect(transmission.transactions.to_a).to be_empty
      end
    end

    context 'when there are transactions' do
      let(:enrollment) do
        FactoryBot.create(:hbx_enrollment, family: FactoryBot.create(:family, :with_primary_family_member))
      end

      let!(:transaction) do
        ::Operations::Transmittable::CreateTransaction.new.call(
          {
            transmission: transmission,
            subject: enrollment,
            key: :hbx_enrollment_expiration_request,
            title: "Enrollment expiration request transaction for #{enrollment.hbx_id}.",
            description: "Transaction request to expire enrollment with hbx id: #{enrollment.hbx_id}.",
            publish_on: Date.today,
            started_at: DateTime.now,
            event: 'initial',
            state_key: :initial
          }
        ).success
      end

      it 'returns the transactions' do
        expect(transmission.transactions.to_a).to eq([transaction])
      end
    end
  end
end
