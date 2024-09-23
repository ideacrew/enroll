# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Transfers::MedicaidGateway::PublishTransferResponse, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  before :all do
    DatabaseCleaner.clean
  end

  let(:obj)  { FinancialAssistance::Operations::Transfers::MedicaidGateway::PublishTransferResponse.new }
  let(:event) { Success(double) }

  let(:transfer_details) do
    {
      transfer_id: "IDC123",
      family_identifier: "fm123",
      application_identifier: "ap123",
      result: "Sucessfully ingested by Enroll"
    }
  end

  before do
    allow(obj).to receive(:build_event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
  end

  context 'When connection is available' do
    context 'transferred_account_response' do
      before do
        @result = obj.call(transfer_details)
      end

      it 'should return success' do
        expect(@result).to be_success
        expect(@result.success).to eq "Returned transfer response to Medicaid Gateway"
      end
    end
  end
end
