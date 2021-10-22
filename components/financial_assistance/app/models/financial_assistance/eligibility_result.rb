# frozen_string_literal: true

module FinancialAssistance
  #store all the results we received from fdsh HUB
  class EligibilityResult
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :evidence, class_name: '::FinancialAssistance::Evidence'

    field :result, type: Symbol
    field :source, type: String
    field :source_transaction_id, type: String
    field :code, type: String
    field :code_description, type: Date
  end
end