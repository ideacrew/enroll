# frozen_string_literal: true

require 'rails_helper'
RSpec.configure do |config|
  config.swagger_docs['v1/swagger.yaml'][:components][:schemas].merge!(
    address: {
      _id: { type: 'string' },
      address_1: { type: 'string' },
      address_2: { type: 'string' },
      address_3: { type: 'string' },
      city: { type: 'string' },
      country_name: { type: 'string' },
      county: { type: 'string' },
      created_at: { type: 'string' },
      kind: { type: 'string' },
      state: { type: 'string' },
      updated_at: { type: 'date' },
      zip: { type: 'string' },
    },
    applicant: {
      type: 'object',
      properties: {
        _id: { type: 'string' },
        aasm_state: { type: 'string' },
        addresses: {
          type: 'array',
          items: {
            '$ref' => '#/components/schemas/address'
          }
        }
      }
    },
    application: {
      type: 'object',
      properties: {
        _id: { type: 'string' },
        applicants: {
          type: 'array',
          items: {
            '$ref' => '#/components/schemas/applicant'
          }
        }
      },
      required: ['_id']
    }
  )
end
