require 'swagger_helper'

RSpec.describe 'applications', type: :request do
  include FinancialAssistance::Engine.routes.url_helpers

  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

  before(:each) do
    sign_in user
  end

  path '/financial_assistance/api/v1/applications' do
    get 'retreives all applications' do
      tags FinancialAssistance::Application
      produces 'application/json'

      response '200', 'index' do
        schema  type: 'array',
                items: {
                  '$ref' => '#/components/schemas/application'
                }

        let!(:application) { FactoryBot.create :financial_assistance_application, :with_applicants, family_id: family.id, aasm_state: 'determined' }

        run_test!

        it 'should output for troubleshooting' do
          get '/financial_assistance/api/v1/applications'
          pp JSON.parse(response.body)
          expect(response.body).to_not be_nil
        end
      end
    end
  end
end