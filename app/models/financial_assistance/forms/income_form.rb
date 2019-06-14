module FinancialAssistance
  module Forms
    class IncomeForm
      include Virtus.model

      attribute :employer_address, AddressForm
      attribute :employer_phone, PhoneForm

      attribute :id, String
      attribute :kind, String
      attribute :frequency_kind, String
      attribute :amount, String
      attribute :employer_name, String
      attribute :start_on, Date
      attribute :end_on, Date

    end
  end
end
