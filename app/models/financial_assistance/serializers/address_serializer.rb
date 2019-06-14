# frozen_string_literal: true
module FinancialAssistance
  module Serializers
    class AddressSerializer < ::ActiveModel::Serializer
      attributes :id, :kind, :address_1, :address_2, :city, :county, :state, :zip

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
