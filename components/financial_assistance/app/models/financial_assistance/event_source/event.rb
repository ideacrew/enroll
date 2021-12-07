# frozen_string_literal: true

module FinancialAssistance
  module EventSource
    #Evidences for an applicant to detrmine his status
    class Evidence
      include Mongoid::Document
      include Mongoid::Timestamps

      field :transaction_id, type: String
      field :transaction_header, type: Hash, default: {}
      field :response_payload, type: Hash, default: {}

    end
  end
end