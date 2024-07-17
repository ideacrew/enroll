# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module EdiGateway
    # Publish event after find and transform family to cv3 family.
    class PublishCv3Family
      include Dry::Monads[:do, :result]
      include EventSource::Command

      def call(params)
        person = yield find_person(params[:person_hbx_id])
        family     = yield find_primary_family(person)
        cv3_family = yield transform_family(family)
        payload    = yield validate_payload(cv3_family)
        event = yield build_event(payload, params[:year])
        result    = yield publish(event)

        Success(result)
      end

      private

      def find_person(person_hbx_id)
        person = Person.where(hbx_id: person_hbx_id).first
        if person
          Success(person)
        else
          Failure("Unable to find person")
        end
      end

      def find_primary_family(person)
        primary_family = person.primary_family
        if primary_family
          Success(primary_family)
        else
          Failure("No primary family exists")
        end
      end

      def transform_family(family)
        cv3_family = Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        cv3_family.success? ? cv3_family : Failure("unable to publish family with hbx_id #{family.hbx_assigned_id} due to #{cv3_family.failure}")
      end

      def validate_payload(value)
        result = AcaEntities::Contracts::Families::FamilyContract.new.call(value)
        if result.success?
          Success(result)
        else
          Failure("unable to publish family with hbx_id #{family.hbx_assigned_id} due to #{result.errors.to_h}")
        end
      end

      def build_event(payload, year)
        event("events.irs_groups.built_requested_seed", attributes: { payload: payload.to_h,
                                                                      year: year })
      end

      def publish(event)
        event.publish
        Success("Successfully published Family")
      end
    end
  end
end
