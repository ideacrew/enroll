# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::SecureMessageActionContract,  dbclean: :after_each do

  describe "secure message action contract" do

    context "sending with missing values should return errors" do
      let(:invalid_params)   { {profile_id: '1234321',  actions_id: '1234', subject: '', body: '' } }
      let(:error_message)   { {:subject => ["Please enter subject"], :body => ["Please enter content"]} }

      before do
        @result = subject.call(invalid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should throw errors' do
        expect(@result.errors.to_h).to eq error_message
      end
    end

    context "sending with missing keys should return errors" do

      let(:invalid_params)   { {profile_id: '1234321',  actions_id: '1234' } }
      let(:error_message)   { {:subject => ["is missing"], :body => ["is missing"]} }

      before do
        @result = subject.call(invalid_params)
      end

      it 'should throw errors' do
        expect(@result.errors.to_h).to eq error_message
      end
    end

    context "sending with all keys and values should not errors" do

      let(:valid_params)   { {profile_id: '1234321',  actions_id: '1234', subject: 'text', body: 'text' } }

      before do
        @result = subject.call(valid_params)
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

  end
end
