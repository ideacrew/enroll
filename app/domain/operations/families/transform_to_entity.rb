# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # This class is responsible for transforming a family object into an entity.
    class TransformToEntity
      include Dry::Monads[:do, :result]

      # Transforms a family object into a family entity.
      #
      # @param family [Object] The family object to be transformed.
      # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure] The result of the transformation.
      def call(family)
        validated_family  = yield validate_family(family)
        transformed_cv    = yield transform_cv(validated_family)
        family_entity     = yield create_entity(transformed_cv)

        Success(family_entity)
      end

      private

      def validate_family(family)
        return Success(family) if family.is_a?(::Family)

        Failure("The input object is expected to be a instance of Family. Input object: #{family}")
      end

      # Transforms the family object into a CV3 family object.
      #
      # @param family [Object] The family object to be transformed.
      # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure] The result of the transformation.
      def transform_cv(family)
        ::Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
      rescue StandardError => e
        Failure("Failed to transform the input family to CV3 family: #{e.message}")
      end

      # Creates a family entity from the transformed CV3 family object.
      #
      # @param transformed_cv [Object] The transformed CV3 family object.
      # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure] The result of the entity creation.
      def create_entity(transformed_cv)
        ::AcaEntities::Operations::CreateFamily.new.call(transformed_cv)
      end
    end
  end
end
