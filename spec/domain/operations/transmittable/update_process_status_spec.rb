# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/transmittable'

RSpec.describe Operations::Transmittable::UpdateProcessStatus, dbclean: :after_each do
  include_context "transmittable job transmission transaction"
  subject { described_class.new }

  context 'sending invalid params' do
    it 'should return a failure with no params' do
      result = subject.call({})
      expect(result.failure?).to be_truthy
    end

    it 'should return a failure without transmittable' do
      result = subject.call({ state: :succeeded,
                              message: "A TEST MESSAGE" })
      expect(result.failure).to eq 'Transmittable objects are not present to update the process status'
    end

    it 'should return a failure without state' do
      result = subject.call({ transmittable_objects: { transaction: transaction },
                              message: "A TEST MESSAGE" })
      expect(result.failure).to eq 'State must be present to update the process status'
    end

    it 'should return a failure without message' do
      result = subject.call({ transmittable_objects: { transaction: transaction }, state: :succeeded })
      expect(result.failure).to eq 'Message must be present to update the process status'
    end
  end

  context 'sending valid params' do
    before do
      @result = subject.call({ transmittable_objects: { transaction: transaction }, state: :succeeded,
                               message: "A TEST MESSAGE" })
    end

    it 'should return a success with all required params' do
      expect(@result.success?).to be_truthy
      expect(transaction.process_status.latest_state).to eq :succeeded
      expect(transaction.process_status.process_states.count).to eq 2
      expect(transaction.process_status.process_states.first.ended_at).not_to eq nil
      expect(transaction.process_status.process_states.last.ended_at).not_to eq nil
      expect(transaction.ended_at).not_to eq nil
      expect(transaction.process_status.process_states.last.state_key).to eq :succeeded
    end
  end
end