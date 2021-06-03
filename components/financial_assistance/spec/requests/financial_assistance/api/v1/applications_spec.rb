require 'swagger_helper'

RSpec.describe 'applications', type: :request do
  include FinancialAssistance::Engine.routes.url_helpers

  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:user) { FactoryBot.create(:user, :person => person) }

  before(:each) do
    sign_in user
  end

  path '/financial_assistance/api/v1/applications' do
    get 'retreives all applications' do
      tags FinancialAssistance::Application
      produces 'application/json'

      response '200', 'index' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :string },
              zoo_id: { type: :string }
            }
          }

        let(:family_id) { BSON::ObjectId.new }
        let(:application) { FactoryBot.create :financial_assistance_application, :with_applicants, family_id: family_id, aasm_state: 'determined' }

        run_test!
      end
    end
  end
end