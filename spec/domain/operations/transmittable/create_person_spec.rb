# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Transmittable::CreatePerson, dbclean: :after_each do
  subject { described_class.new }
  let(:application) {File.read("./spec/test_data/application_payload.json")}
  let(:person) { JSON.parse(application)["applicants"].first }

  context 'sending invalid params' do
    it 'should return a failure with missing key' do
      result = subject.call({})
      expect(result.failure).to eq('Person is blank')
    end

    it 'should return a failure when key is not a symbol' do
      person["name"] = {}
      result = subject.call(person)
      expect(result.failure).to eq('Unable to create Person due to invalid params')
    end
  end

  context 'sending valid params' do
    it 'should return a success' do
      result = subject.call(person)
      expect(result.success?).to be_truthy
    end
  end
end
