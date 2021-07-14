require 'swagger_helper'

RSpec.describe 'applications', type: :request do

  path '/api/v1/applications' do
    
    get 'edit an application' do
      tags Users
      produces 'application/json'
      parameter name: :id, :in => :path, :type => :string 

        response '200' 'edit made' do
          schema type: :object,
            properties: {
              id: { type: :string },
              title: { type: :string },
              content: { type: :string }
            },
            required: [ 'id', 'title', 'content' ]

          let(:id) { Applications.edit(title: 'foo', content: 'bar').id }
          run_test!
        end
      end
    end
  end
