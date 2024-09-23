# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecCheck, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  let!(:person) { FactoryBot.create(:person, hbx_id: "b3dc8e08e28e487f80285fb79681b337") }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person, hbx_assigned_id: "10028") }
  let(:application_id) { "614cd09ca54d7584cbc9532d" }
  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: family.id,
                      id: application_id)
  end
  let!(:missing_family_application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: "invalid",
                      id: "id123")
  end

  let(:operation) { ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecCheck.new }

  context 'Given invalid data' do
    it 'should fail when the person does not exist' do
      invalid_id = "invalid_id"
      result = operation.call(invalid_id)
      expect(result).not_to be_success
      expect(result.failure).to eq "Unable to find Person with ID invalid_id."
    end
  end

  context 'Given a valid person' do
    before :each do
      allow(operation).to receive(:construct_payload).with(person).and_return(Success({}))
      allow(operation).to receive(:publish).with({}).and_return(Success())
      @result = operation.call(person.hbx_id)
    end

    it 'should succeed' do
      expect(@result).to be_success
    end
  end
end