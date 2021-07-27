# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::Documents::DocumentContract,  dbclean: :after_each do

  describe 'message contract' do

    context 'sending with missing values should return errors' do
      let(:invalid_params) { {title: "", creator: "", subject: "", doc_identifier: "", format: ""} }
      let(:error_message) do
        {
          :creator => ["Missing creator for document."],
          :doc_identifier => ["Response missing doc identifier."],
          :format => ["Invalid file format."],
          :subject => ["Missing subject for document."],
          :title => ["Missing title for document."]
        }
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(subject.call(invalid_params)).to be_a ::Dry::Validation::Result
      end

      it 'should throw errors' do
        expect(subject.call(invalid_params).errors.to_h).to eq error_message
      end
    end

    context 'sending with missing keys should return errors' do

      let(:invalid_params) { {} }
      let(:error_message) do
        {:title => ['is missing', 'must be a string'], :creator => ['is missing', 'must be a string'],
         :subject => ['is missing', 'must be a string'], :doc_identifier => ['is missing', 'must be a string'], :format => ['is missing', 'must be a string']}
      end

      it 'should throw errors' do
        expect(subject.call(invalid_params).errors.to_h).to eq error_message
      end
    end

    context "sending with all keys and values should not errors" do

      let(:valid_params) do
        {title: 'test', creator: 'hbx_staff', subject: 'notice',
         doc_identifier: BSON::ObjectId.new.to_s, format: 'application/pdf'}
      end


      it 'should return Dry::Validation::Result object' do
        expect(subject.call(valid_params)).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(subject.call(valid_params).errors.to_h).to be_empty
      end
    end
  end
end
