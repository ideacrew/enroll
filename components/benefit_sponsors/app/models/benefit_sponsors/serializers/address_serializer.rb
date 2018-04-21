module BenefitSponsors
  module Serializers
    class AddressSerializer < ActiveModel::Serializer
      attributes :address_1, :address_2, :city, :state, :zip, :office_kind_options, :state_options


      def office_kind_options
        object.office_kinds
      end

      def state_options
        State::NAME_IDS
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
