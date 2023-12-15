# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transmittable::Transaction, type: :model, dbclean: :after_each do
  let(:transmission) { FactoryBot.create(:transmittable_transmission) }
  let(:enrollment) do
    FactoryBot.create(:hbx_enrollment, family: FactoryBot.create(:family, :with_primary_family_member))
  end

  let(:transaction) do
    ::Operations::Transmittable::CreateTransaction.new.call(
      {
        transmission: transmission,
        subject: enrollment,
        key: :hbx_enrollments_expiration_request,
        title: "Enrollment expiration request transaction for #{enrollment.hbx_id}.",
        description: "Transaction request to expire enrollment with hbx id: #{enrollment.hbx_id}.",
        publish_on: Date.today,
        started_at: DateTime.now,
        event: 'initial',
        state_key: :initial
      }
    ).success
  end

  describe '#to_global_id' do
    it 'responds to to_global_id' do
      expect(transaction.respond_to?(:to_global_id)).to be_truthy
    end

    it 'returns the GlobalID URI' do
      expect(
        transaction.to_global_id.uri.to_s
      ).to eq("gid://enroll/#{described_class}/#{transaction.id}")
    end
  end

  describe '#transmissions' do
    it 'returns the transmissions' do
      expect(transaction.transmissions.to_a).to eq([transmission])
    end
  end
end
