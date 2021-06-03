require 'swagger_helper'

RSpec.describe 'applications', type: :request do

  path '/api/v1/applications' do
    
    get 'edit an application' do
      tags Users
      produces 'application/json'
      parameter name: :id, :in => :path, :type => :string 

        response '200' 'index' do
          schema type: :object,
            properties: {
              family_id: { type: :string }
            },
            required: [ 'family_id' ]

          let(:family_id) { Applications.index(family_id: 'family id') }
          run_test!
        end

        response '404', 'user not found' do
          let(:family_id) { 'invalid' }
          run_test!
        end
      end
    end
  end
