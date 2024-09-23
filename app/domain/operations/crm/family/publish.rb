# frozen_string_literal: true

module Operations
  module Crm
    module Family
      # This operation is responsible for publishing an event for a a primary person.
      class Publish
        include Dry::Monads[:do, :result]
        include EventSource::Command

        # Publishes an event for a given person identified by hbx_id.
        #
        # @param hbx_id [String] The HBX ID of the person.
        # @return [Dry::Monads::Result] The result of the publish operation.
        def call(hbx_id:)
          person            = yield find_person(hbx_id)
          family            = yield find_primary_family(person)
          headers           = yield headers(family, person)
          transformed_cv    = yield construct_cv_transform(family, hbx_id)
          family_entity     = yield create_family_entity(transformed_cv)
          es_event          = yield create_es_event(family_entity, headers)
          published_result  = yield publish_es_event(es_event, hbx_id)

          Success(published_result)
        end

        private

        # Finds a person by their HBX ID.
        #
        # @param hbx_id [String] The HBX ID of the person.
        # @return [Dry::Monads::Result] The result containing the person or an error message.
        def find_person(hbx_id)
          result = ::Operations::People::Find.new.call({ person_hbx_id: hbx_id })

          if result.success?
            Success(result.value!)
          else
            Failure("Provide a valid person_hbx_id to fetch person. Invalid input hbx_id: #{hbx_id}")
          end
        end

        # Finds the primary family of a given person.
        #
        # @param person [Person] The person object.
        # @return [Dry::Monads::Result] The result containing the family or an error message.
        def find_primary_family(person)
          family = person.primary_family

          if family
            Success(family)
          else
            Failure("Primary Family does not exist with given hbx_id: #{person.hbx_id}")
          end
        end

        # Constructs headers for the event.
        #
        # @param family [Family] The family object.
        # @param person [Person] The person object.
        # @return [Dry::Monads::Result] The result containing the headers.
        def headers(family, person)
          eligible_dates = [person.created_at, person.updated_at, family.created_at, family.updated_at].compact

          Success({ after_updated_at: eligible_dates.max, before_updated_at: eligible_dates.min })
        end

        # Constructs a CV transform for the family.
        #
        # @param family [Family] The family object.
        # @param hbx_id [String] The HBX ID of the person.
        # @return [Dry::Monads::Result] The result containing the transformed CV or an error message.
        def construct_cv_transform(family, hbx_id)
          ::Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        rescue StandardError => e
          Failure("Failed to transform family with primary person_hbx_id: #{hbx_id} to CV: #{e.message}")
        end

        # Creates a family entity from the transformed CV.
        #
        # @param transformed_cv [Hash] The transformed CV.
        # @return [Dry::Monads::Result] The result containing the family entity.
        def create_family_entity(transformed_cv)
          ::AcaEntities::Operations::CreateFamily.new.call(transformed_cv)
        end

        # Creates an event source event for the family entity.
        #
        # @param family_entity [FamilyEntity] The family entity object.
        # @param headers [Hash] The headers for the event.
        # @return [Dry::Monads::Result] The result containing the event.
        def create_es_event(family_entity, headers)
          event(
            'events.families.created_or_updated',
            attributes: { before_save_cv_family: {}, after_save_cv_family: family_entity.to_h },
            headers: headers
          )
        end

        # Publishes the event source event.
        #
        # @param es_event [EventSource::Event] The event source event.
        # @param hbx_id [String] The HBX ID of the person.
        # @return [Dry::Monads::Result] The result of the publish operation.
        def publish_es_event(es_event, hbx_id)
          es_event.publish
          Success("Successfully published event: #{es_event.name} for family with primary person hbx_id: #{hbx_id}")
        end
      end
    end
  end
end
