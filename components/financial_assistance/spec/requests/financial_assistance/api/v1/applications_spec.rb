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

        # it 'should output for troubleshooting' do
        #   get '/financial_assistance/api/v1/applications'
        #   puts response.body
        #   expect(response.body).to_not be_nil
        # end
      end
    end
    post 'creates an application' do
      tags FinancialAssistance::Application
      produces 'application/json'
      # parameter name: 'Authorization', in: :header, type: :string, default: 'Bearer c36e6eadde881ca7'
      parameter name: :application, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          body: { type: :string }
        },
        required: %w[title body]
      }

      response '200', 'create' do
        schema type: object,
               '$ref' => '#/components/schemas/application'
      end
      
      run_test!

    end
  end
end