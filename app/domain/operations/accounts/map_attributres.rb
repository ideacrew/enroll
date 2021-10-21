# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Create a new Keycloak Account
    class MapAtttributes
      include Dry::Monads[:result, :do, :try]

      def call(params)
        values = yield validate(params)
        attributes = yield map_attributes(values)

        Success(attributes)
      end

      private

      def validate(params)
        AcaEntities::Accounts::Contracts::AccountContract.new.call(
          params[:account]
        )
      end

      def map_attributes(attributes)
        attrs =
          attributes.reduce({}) do |map, (k, v)|
            if v.is_a? Hash
              map.merge!(k.underscore.to_sym => map_attributes(v))
            elsif k == 'createdTimestamp'
              map.merge!(created_at: epoch_to_time(v))
            else
              map.merge!(k.underscore.to_sym => v)
            end
          end

        Success(attrs)
      end

      def epoch_to_time(value)
        Time.at(value / 1000)
      end
    end
  end
end
