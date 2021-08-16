# frozen_string_literal: true

module FinancialAssistance
  class VerificationHistory
    include Mongoid::Document
    include Mongoid::Timestamps

    field :action, type: String
    field :modifier, type: String
    field :update_reason, type: String

  end
end