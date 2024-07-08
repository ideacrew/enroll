# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class CreateOrUpdateConsumerRole
      include Dry::Monads[:result, :do]

      def call(params:)
        values = yield validate(params[:applicant_params])
        entity = yield create_entity(values)
        result = yield create_consumer_role(entity, params[:family_member], optimistic_upstream_interpretation: params[:optimistic_upstream_coverage_attestation_interpretation])

        Success(result)
      end

      private

      def validate(params)
        result = Validators::Families::ConsumerRoleContract.new.call(params)

        if result.success?
          Success(result)
        else
          Failure(result)
        end
      end

      def create_entity(values)
        result = Entities::ConsumerRole.new(values.to_h)

        Success(result)
      end

      def create_consumer_role(entity, family_member, optimistic_upstream_interpretation: false)
        person = family_member.person
        if person.consumer_role.present?
          consumer_role_params = entity.to_h
          consumer_role = person.consumer_role
          return Success(consumer_role) if consumer_role.citizen_status == consumer_role_params[:citizen_status] && consumer_role.is_applying_coverage == consumer_role_params[:is_applying_coverage]
          if optimistic_upstream_interpretation && !entity.is_applying_coverage
            updated_params = entity.to_h.except(:is_applying_coverage)
            person.consumer_role.assign_attributes(updated_params)
          else
            person.consumer_role.assign_attributes(consumer_role_params)
          end
        else
          person.build_consumer_role({:is_applicant => false}.merge(entity.to_h))
        end

        # All persons with a consumer_role are required to have a demographics_group
        person.build_demographics_group
        person.save!

        Success(person.consumer_role)
      rescue StandardError => e
        Failure("Consumer role creation failed: #{e}")
      end
    end
  end
end
