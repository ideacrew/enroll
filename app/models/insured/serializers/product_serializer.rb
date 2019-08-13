# frozen_string_literal: true

module Insured
  module Serializers
    class ProductSerializer < ::ActiveModel::Serializer
      attributes :id, :application_period, :name, :hios_id, :issuer_profile_id, :metal_level, :kind

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
