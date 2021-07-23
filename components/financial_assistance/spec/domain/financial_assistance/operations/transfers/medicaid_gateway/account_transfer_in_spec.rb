# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferIn, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:xml) { File.read(::FinancialAssistance::Engine.root.join('spec', 'shared_examples', 'medicaid_gateway', 'Simple_Test_Case_E_New.xml')) }


  context 'success' do
    context 'with valid application' do
      before do
        @result = subject.call(xml)
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return success with message' do
        expect(@result.success).to eq('Successfully transferred in account')
      end
    end
  end
end
