# frozen_string_literal: true

module FinancialAssistance
  module Serializers
    class IncomeSerializer < ::ActiveModel::Serializer
      attributes :id, :employer_name, :kind, :frequency_kind, :amount, :start_on, :end_on

      has_one :employer_address, serializer: ::FinancialAssistance::Serializers::AddressSerializer
      has_one :employer_phone, serializer: ::FinancialAssistance::Serializers::PhoneSerializer

      def amount
        object.amount.to_s
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
