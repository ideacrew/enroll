# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # This class is responsible for transforming a family object into an entity.
    class TransformToEntity
      include Dry::Monads[:do, :result]

      # @!attribute [r] transform_result
      #   @return [Symbol] The result of the transformation to entity operation.
      #     :success - The transformation was successful.
      #     :failure - The transformation failed.
      #     :error - The transformation encountered an error.
      attr_reader :transform_result

      # Transforms a family object into an entity.
      #
      # @param family [Family] The family object to be transformed.
      # @return [Dry::Monads::Result] The result of the transformation.
      def call(family)
        validated_family  = yield validate_family(family)
        transformed_cv    = yield transform_cv(validated_family)
        family_entity     = yield create_entity(transformed_cv)

        Success(family_entity)
      end

      private

      # Validates the family object.
      #
      # @param family [Object] The object to be validated.
      # @return [Dry::Monads::Result] The result of the validation.
      def validate_family(family)
        return Success(family) if family.is_a?(::Family)

        @transform_result = :failure
        Failure("The input object is expected to be an instance of Family. Input object: #{family}")
      end

      # Transforms the family object to a CV3 family.
      #
      # @param family [Family] The validated family object.
      # @return [Dry::Monads::Result] The result of the transformation.
      def transform_cv(family)
        transform_result = ::Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        return transform_result if transform_result.success?

        @transform_result = :failure
        Failure(transform_result.failure)
      rescue StandardError => e
        @transform_result = :error
        Failure("Failed to transform the input family to CV3 family: #{e.message}")
      end

      # Creates an entity from the transformed CV3 family.
      #
      # @param transformed_cv [Object] The transformed CV3 family object.
      # @return [Dry::Monads::Result] The result of the entity creation.
      def create_entity(transformed_cv)
        entity_result = ::AcaEntities::Operations::CreateFamily.new.call(transformed_cv)
        if entity_result.success?
          @transform_result = :success
          return entity_result
        end

        @transform_result = :failure
        Failure(entity_result.failure)
      rescue StandardError => e
        @transform_result = :error
        Failure("Failed to create entity: #{e.message}")
      end
    end
  end
end
