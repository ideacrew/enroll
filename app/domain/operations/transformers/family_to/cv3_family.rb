# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module Operations
  module Transformers
    module FamilyTo
      # Person params to be transformed.
      class Cv3Family
        # constructs cv3 payload for fdsh gateway.

        include Dry::Monads[:result, :do]
        include Acapi::Notifiers
        require 'securerandom'

        def call(family)
          request_payload = yield construct_payload(family)

          Success(request_payload)
        end

        private

        def construct_payload(family)
          payload = {
            hbx_id: family.primary_applicant.hbx_id,  # TODO: Need to change witth family hbx_id once hbx_id added to family
            family_members: transform_family_members(family.family_members)
          }

          Success(payload)
        end

        def transform_family_members(family_members)
          family_members.collect do |member|
            {
              hbx_id: member.hbx_id,
              is_primary_applicant: member.is_primary_applicant,
              is_consent_applicant: member.is_consent_applicant,
              is_coverage_applicant: member.is_coverage_applicant,
              is_active: member.is_active,
              person: transform_person(member.person)
            }
          end
        end

        def transform_person(person)
          Operations::Transformers::PersonTo::Cv3Person.new.call(person).value!
        end
      end
    end
  end
end
