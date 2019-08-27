# frozen_string_literal: true

module Insured
  module Serializers
    class ProductSerializer < ::ActiveModel::Serializer
      attributes :id, :active_year, :display_carrier_logo, :nationwide, :application_period, :title, :hios_id, :issuer_profile_id, :metal_level_kind, :kind

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
