# frozen_string_literal: true

require 'rails_helper'
require 'aca_entities/serializers/xml/medicaid/atp'
require 'aca_entities/atp/transformers/cv/family'

RSpec.describe ::FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferIn, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:xml) { File.read(::FinancialAssistance::Engine.root.join('spec', 'shared_examples', 'medicaid_gateway', 'Simple_Test_Case_E_New.xml')) }

  let(:record) { ::AcaEntities::Serializers::Xml::Medicaid::Atp::AccountTransferRequest.parse(xml) }

  let(:transformed) { ::AcaEntities::Atp::Transformers::Cv::Family.transform(record.to_hash(identifier: true)) }

  context 'success' do
    context 'with valid payload' do
      before do
        @result = subject.call(transformed)
      end

      it 'should return success' do
        expect(@result).to be_success
      end
    end
  end
end