module Importers
  class ConversionEmployeePolicyDelete < ConversionEmployeePolicyCommon
    validate :delete_forbidden

    def delete_forbidden
      errors.add(:action, "delete actions are ignored")
    end
  end
end
