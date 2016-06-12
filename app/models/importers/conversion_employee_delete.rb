module Importers
  class ConversionEmployeeDelete < ConversionEmployeeCommon
      validates_length_of :fein, is: 9

      validate :prohibit_delete

      def prohibit_delete
        errors.add(:action, "delete instructions are ignored")
      end

      def save
        valid?
      end
  end
end
