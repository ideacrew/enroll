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
    context 'with valid application id' do
      let(:family) { FactoryBot.create(:family, :with_primary_family_member) }

      before do
        family.primary_person.emails.create(kind: "home", address: "fakeemail@email.com")
        @application = FactoryBot.create(:financial_assistance_application, transfer_id: transfer_id, family_id: family.id)
        @expected_response =
          {
            family_identifier: family.hbx_assigned_id.to_s,
            application_identifier: @application.hbx_id,
            result: "Success"
          }
      end

      it 'should return success' do
        result = subject.call(@application.id)
        expect(result).to be_success
      end

      it 'should return success with message' do
        result = subject.call(@application.id)
        expect(result.value!).to eq(@expected_response)
      end

      it 'should trigger account transfer notice' do
        expect(::Operations::Notices::IvlAccountTransferNotice).to receive_message_chain('new.call').with(family: family)
        subject.call(@application.id)
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
        expect(@result.failure).to eq("Unable to find Application by ID.")
      end
    end

    context 'with missing family' do
      before do
        @application = FactoryBot.create(:financial_assistance_application, transfer_id: transfer_id, family_id: "missing")
        @result = subject.call(@application.id)
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