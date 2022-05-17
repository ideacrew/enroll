# frozen_string_literal: true

require "rails_helper"

RSpec.describe Operations::Individual::DetermineVerifications, dbclean: :after_each do

  subject do
    described_class.new.call(id: consumer_role_id)
  end

  let(:consumer_role_id) { consumer_role.id }

  context 'when consumer role id is nil' do
    let(:consumer_role_id) { nil }

    it 'returns failure' do
      expect(subject.failure?).to eq true
    end
  end

  context 'when person is nil' do
    let(:consumer_role) { ConsumerRole.new }

    it 'returns failure' do
      expect(subject.failure?).to eq true
    end
  end

  context 'when person and consumer role exists' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:consumer_role) { person.consumer_role }

    it 'returns success' do
      expect(subject.success?).to eq true
    end

    it 'updates consumer_role state to verification_outstanding' do
      expect(consumer_role.aasm_state).to eq 'unverified'
      subject
      expect(consumer_role.reload.aasm_state).to eq 'verification_outstanding'
    end
  end
end
