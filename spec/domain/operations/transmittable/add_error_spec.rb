# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/transmittable'

RSpec.describe Operations::Transmittable::AddError, dbclean: :after_each do
  include_context "transmittable job transmission transaction"
  subject { described_class.new }

  context 'sending invalid params' do
    it 'should return a failure with no params' do
      result = subject.call({})
      expect(result.failure?).to be_truthy
    end

    it 'should return a failure without transmittable' do
      result = subject.call({ key: :succeeded,
                              message: "A TEST MESSAGE" })
      expect(result.failure).to eq 'Transmittable objects are not present to update the process status'
    end

    it 'should return a failure without key' do
      result = subject.call({ transmittable_objects: { transaction: transaction },
                              message: "A TEST MESSAGE" })
      expect(result.failure).to eq 'key must be present to update the process status'
    end

    it 'should return a failure without message' do
      result = subject.call({ transmittable_objects: { transaction: transaction }, key: :succeeded })
      expect(result.failure).to eq 'message must be present to update the process status'
    end
  end

  context 'sending valid params' do
    before do
      @result = subject.call({ transmittable_objects: { transaction: transaction, transmission: transmission, job: job }, key: :test_key,
                               message: "A TEST MESSAGE" })
    end

    it 'should return a success with all required params' do
      expect(@result.success?).to be_truthy
      expect(transaction.transmittable_errors.first.key).to eq :test_key
      expect(transmission.transmittable_errors.first.key).to eq :test_key
      expect(job.transmittable_errors.first.key).to eq :test_key
    end
  end
end