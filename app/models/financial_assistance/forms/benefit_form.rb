# frozen_string_literal: true

module FinancialAssistance
  module Forms
    class BenefitForm
      include Virtus.model

      attribute :employer_address, AddressForm
      attribute :employer_phone, PhoneForm

      attribute :id, String
      attribute :employer_id, String
      attribute :start_on, Date
      attribute :end_on, Date
      attribute :kind, String
      attribute :insurance_kind, String
      attribute :employer_name, String
      attribute :is_esi_waiting_period, Boolean
      attribute :is_esi_mec_met, Boolean
      attribute :esi_covered, String
      attribute :employee_cost, String
      attribute :employee_cost_frequency, Boolean
    end
  end
end
