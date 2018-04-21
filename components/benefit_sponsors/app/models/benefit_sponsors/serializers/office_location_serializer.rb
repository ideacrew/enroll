module BenefitSponsors
  module Serializers
    class OfficeLocationSerializer < ActiveModel::Serializer
      attributes :is_primary

      has_one :phone
      has_one :address

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
