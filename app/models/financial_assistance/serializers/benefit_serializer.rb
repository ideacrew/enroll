module FinancialAssistance
  module Serializers
    class BenefitSerializer < ::ActiveModel::Serializer
      attributes :id, :employer_name, :kind, :start_on, :end_on, :insurance_kind,
                 :is_esi_waiting_period, :is_esi_mec_met, :esi_covered, :employee_cost,
                 :employee_cost_frequency, :employer_id

      has_one :employer_address, serializer: ::FinancialAssistance::Serializers::AddressSerializer
      has_one :employer_phone, serializer: ::FinancialAssistance::Serializers::PhoneSerializer

      def employee_cost
        object.employee_cost.to_s
      end

      # provide defaults(if any needed) that were not set on Model
      def attributes(*args)
        hash = super
        unless object.persisted?

        end
        hash
      end
    end
  end
end
