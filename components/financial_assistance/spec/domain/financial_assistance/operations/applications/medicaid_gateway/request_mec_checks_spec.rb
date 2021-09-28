# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecChecks, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let!(:person) { FactoryBot.create(:person, hbx_id: "b3dc8e08e28e487f80285fb79681b337") }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person, hbx_assigned_id: "10028") }
  let(:application_id) { "614cd09ca54d7584cbc9532d" }
  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: family.id,
                      id: application_id)
  end
  let(:missing_family_application_id) { "id123" }
  let!(:missing_family_application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: "invalid",
                      id: missing_family_application_id)
  end

  let(:operation) { ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecChecks.new }

  context 'Given invalid data' do
    it 'should fail when the application does not exist' do
      invalid_id = "invalid_id"
      result = operation.call(invalid_id)
      expect(result).not_to be_success
      expect(result.failure).to eq "Unable to find Application with ID invalid_id."
    end

    it 'should fail when the family does not exist' do
      result = operation.call(missing_family_application_id)
      expect(result).not_to be_success
      expect(result.failure).to eq "Unable to find Family with ID invalid."
    end
  end

  context 'Given a valid application' do
    before :each do
      @result = operation.call(application_id)
    end

    it 'should succeed' do
      expect(@result).to be_success
    end
  end
end