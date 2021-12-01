# frozen_string_literal: true

require 'rails_helper'
require 'aca_entities/serializers/xml/medicaid/atp'
require 'aca_entities/atp/transformers/cv/family'

RSpec.describe ::FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferIn, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:xml) { File.read(::FinancialAssistance::Engine.root.join('spec', 'shared_examples', 'medicaid_gateway', 'Simple_Test_Case_E_New.xml')) }

  let(:record) { ::AcaEntities::Serializers::Xml::Medicaid::Atp::AccountTransferRequest.parse(xml) }

  let(:transformed) { ::AcaEntities::Atp::Transformers::Cv::Family.transform(record.to_hash(identifier: true)) }

  let(:zip_double) { double }

  context 'success' do
    context 'with valid payload' do
      before do
        ::BenefitMarkets::Locations::CountyZip.create(zip: "04330", state: "ME", county_name: "Kennebec")
        @result = subject.call(transformed)
      end

      it 'should return success if zips are present in database' do
        expect(@result).to be_success
      end
    end
  end

  context 'failure' do
    context 'with counties not matching those present in database' do
      before do
        @result = subject.call(transformed)
      end

      it 'should return failure if no zips are present' do
        expect(@result).to eq(Failure("Unable to find county objects for zips [\"04330\", \"04330\", \"04330\"]"))
      end
    end
  end
end