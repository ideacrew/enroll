require 'swagger_helper'

RSpec.describe 'applications', type: :request do

  path '/api/v1/applications' do

    get 'retreives all applications' do
      tags Users
      produces 'application/json'
      parameter name: :id, :in => :path, :type => :string 

        response '200', 'index' do
          schema type: :object,
            properties: {
              id: { type: :string },
              family_id: { type: :string }
            },
            required: [ 'family_id' ]
          let(:family_id) { BSON::ObjectId.new }
          let(:application) { FactoryBot.create :financial_assistance_application, :with_applicants, family_id: family_id, aasm_state: 'determined' }

          let(:id) { application.id }
          run_test!
        end

        response '404', 'user not found' do
          let(:family_id) { 'invalid' }
          run_test!
        end
      end
    end
  end
