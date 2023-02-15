# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Operation is for finding family with person person hbx_id and publishing an event 'enroll.families.found_by'
    class FindBy
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command

      # params = { { person_hbx_id: 10239, year: 2022 } }
      def call(params)
        person     = yield find_person(params[:response][:person_hbx_id])
        family     = yield find_primary_family(person)
        cv3_family = yield transform_family(family)
        payload    = yield validate_payload(cv3_family, person)
        event      = yield build_event(payload, params)
        result     = yield publish(event)

        Success(result)
      end

      private

      def build_event(payload, params)
        event('events.families.found_by', attributes: {
                family: payload.to_h,
                primary_person_hbx_id: params[:response][:person_hbx_id]
              }, headers: { correlation_id: params[:correlation_id] })
      end

      def find_person(person_hbx_id)
        person = Person.where(hbx_id: person_hbx_id).first
        if person
          Success(person)
        else
          Failure("Unable to find person with hbx_id: #{person_hbx_id}")
        end
      end

      def find_primary_family(person)
        primary_family = person.primary_family
        if primary_family
          Success(primary_family)
        else
          Failure("No primary family exists for person with hbx_id: #{person.hbx_id}")
        end
      end

      def publish(event)
        event.publish
        Success("Successfully published event: #{event.name}")
      end

      def transform_family(family)
        Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
      end

      def validate_payload(cv3_family, person)
        result = AcaEntities::Contracts::Families::FamilyContract.new.call(cv3_family)

        if result.success?
          Success(result)
        else
          Failure("Invalid Cv3Family payload for primary_person with hbx_id: #{person.hbx_id} due to #{result.errors.to_h}")
        end
      end
    end
  end
end
