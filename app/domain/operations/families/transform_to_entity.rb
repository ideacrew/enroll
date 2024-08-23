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
      # @param family [Family] The family object to be transformed.
      # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure] The result of the transformation.
      def call(family)
        validated_family  = yield validate_family(family)
        transformed_cv    = yield transform_cv(validated_family)
        family_entity     = yield create_entity(transformed_cv)

        Success([:success, family_entity])
      end

      private

      # Validates the family object.
      #
      # @param family [Family] The family object to be validated.
      # @return [Dry::Monads::Result::Success<Family>, Dry::Monads::Result::Failure<Array<Symbol, String>>] The result of the validation.
      def validate_family(family)
        return Success(family) if family.is_a?(::Family)

        Failure([:failure, "The input object is expected to be an instance of Family. Input object: #{family}"])
      end

      # Transforms the family object into a CV3 family object.
      #
      # @param family [Family] The family object to be transformed.
      # @return [Dry::Monads::Result::Success<Object>, Dry::Monads::Result::Failure<Array<Symbol, String>>] The result of the transformation.
      def transform_cv(family)
        transform_result = ::Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        return transform_result if transform_result.success?

        Failure([:failure, transform_result.failure])
      rescue StandardError => e
        Failure([:error, "Failed to transform the input family to CV3 family: #{e.message}"])
      end

      # Creates a family entity from the transformed CV3 family object.
      #
      # @param transformed_cv [Object] The transformed CV3 family object.
      # @return [Dry::Monads::Result::Success<Object>, Dry::Monads::Result::Failure<Array<Symbol, String>>] The result of the entity creation.
      def create_entity(transformed_cv)
        entity_result = ::AcaEntities::Operations::CreateFamily.new.call(transformed_cv)
        return entity_result if entity_result.success?

        Failure([:failure, entity_result.failure])
      rescue StandardError => e
        Failure([:error, "Failed to create entity: #{e.message}"])
      end
    end
  end
end
