# frozen_string_literal: true

module Insured
  module Serializers
    class FamilySerializer < ::ActiveModel::Serializer
      attributes :id, :hbx_id, :effective_on

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
