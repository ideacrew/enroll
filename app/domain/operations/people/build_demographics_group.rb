# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    # Class for building demographics_group and alive_status on a person
    class BuildDemographicsGroup
      include Dry::Monads[:result, :do]

      def call(person)
        result = yield build_demographics_group(person)

        Success(result)
      end

      private

      def build_demographics_group(person)
        return Failure('person does not have a consumer_role') unless person.consumer_role.present?

        person.demographics_group = DemographicsGroup.new if person.demographics_group.blank?
        build_alive_status(person.demographics_group)

        Success('demographics_group and alive_status added to person')
      end

      def build_alive_status(demographics_group)
        return if demographics_group&.alive_status&.present?
        demographics_group.alive_status = AliveStatus.new
      end
    end
  end
end