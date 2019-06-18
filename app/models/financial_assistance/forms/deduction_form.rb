# frozen_string_literal: true

module FinancialAssistance
  module Forms
    class DeductionForm
      include Virtus.model

      attribute :id, String
      attribute :kind, String
      attribute :frequency_kind, String
      attribute :amount, String
      attribute :start_on, Date
      attribute :end_on, Date
    end
  end
end
