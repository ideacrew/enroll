# frozen_string_literal: true

require 'rails_helper'
require 'aca_entities/serializers/xml/medicaid/atp'
require 'aca_entities/atp/transformers/cv/family'

RSpec.describe ::FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferResponse, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  before :all do
    DatabaseCleaner.clean
  end

  let(:transfer_id) { "tr123" }

  context 'success' do
    context 'with valid transfer id' do
      before do
        family = FactoryBot.create(:family, :with_primary_family_member)
        application = FactoryBot.create(:financial_assistance_application, transfer_id: transfer_id, family_id: family.id)
        @expected_response =
          {
            family_identifier: family.hbx_assigned_id.to_s,
            application_identifier: application.hbx_id,
            result: "Success"
          }
        @result = subject.call(transfer_id)
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return success with message' do
        expect(@result.value!).to eq(@expected_response)
      end
    end
  end

  context 'failure' do
    context 'with missing application' do
      before do
        @result = subject.call(transfer_id)
      end

      it 'should return failure' do
        expect(@result).not_to be_success
      end

      it 'should return expected error message' do
        expect(@result.failure).to eq("Unable to find Application by Transfer ID.")
      end
    end

    context 'with missing family' do
      before do
        @application = FactoryBot.create(:financial_assistance_application, transfer_id: transfer_id, family_id: "missing")
        @result = subject.call(transfer_id)
      end

      it 'should return failure' do
        expect(@result).not_to be_success
      end

      it 'should return expected error message' do
        expect(@result.failure).to eq("Unable to find Family with ID #{@application.family_id}.")
      end
    end
  end
end