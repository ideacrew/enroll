# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Create a new Keycloak Account
    class MapAttributes
      include Dry::Monads[:result, :do, :try]

      def call(params)
        # values = yield validate(params)
        values = yield transform(params)

        Success(values)
      end

      private

      def transform(attributes)
        values = map_attributes(attributes)
        values.blank? ? Failure(values) : Success(values)
      end

      def map_attributes(attributes)
        if attributes.is_a? Array
          attributes.collect { |h| map_attributes(h) }
        else
          attributes.reduce({}) do |map, (k, v)|
            if v.is_a? Hash
              map.merge!(k.underscore.to_sym => map_attributes(v))
            elsif k == 'createdTimestamp'
              map.merge!(created_at: epoch_to_time(v))
            else
              map.merge!(k.underscore.to_sym => v)
            end
          end
        end
      end

      def epoch_to_time(value)
        Time.at(value / 1000)
      end
    end
  end
end
