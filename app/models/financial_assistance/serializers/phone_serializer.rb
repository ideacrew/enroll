module FinancialAssistance
  module Serializers
    class PhoneSerializer < ::ActiveModel::Serializer
      attributes :id, :full_phone_number

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
