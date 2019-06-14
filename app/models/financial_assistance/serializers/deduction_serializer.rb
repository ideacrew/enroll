# frozen_string_literal: true

module FinancialAssistance
  module Serializers
    class DeductionSerializer < ::ActiveModel::Serializer
      attributes :id, :kind, :frequency_kind, :amount, :start_on, :end_on

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
