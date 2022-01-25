# frozen_string_literal: true

module FinancialAssistance
  #Store the history of each transaction a user or admin has performed on an evidence
  class VerificationHistory
    include Mongoid::Document
    include Mongoid::Timestamps

    field :action, type: String
    field :modifier, type: String
    field :update_reason, type: String
    field :updated_by, type: String

  end
end