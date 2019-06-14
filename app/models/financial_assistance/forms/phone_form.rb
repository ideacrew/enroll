module FinancialAssistance
  module Forms
    class PhoneForm
      include Virtus.model

      attribute :id, String
      attribute :full_phone_number, String

    end
  end
end
