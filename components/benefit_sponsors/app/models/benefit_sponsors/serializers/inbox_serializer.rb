module BenefitSponsors
  module Serializers
    class InboxSerializer < ActiveModel::Serializer
      attributes :access_key

      has_many :messages

      def is_persisted?
        object.persisted?
      end

      # provide defaults(if any needed) that were not set no Model
      def attributes(*args)
        hash = super
        unless object.persisted?
          
        end
        hash
      end
    end
  end
end
