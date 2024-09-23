# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Transformers
    module Cv3ApplicationTo
      # Cv3Application will be transformed to request payload that is needed for IdentifySlcspWithPediatricDentalCosts.
      class IdentifySlcspRequest
        include Dry::Monads[:do, :result]

        def call(cv3_application)
          cv3_application = yield validate(cv3_application)
          @family         = yield find_family(cv3_application)
          request_payload = yield construct_payload(cv3_application)

          Success([@family, request_payload])
        end

        private

        def validate(cv3_application)
          if cv3_application.is_a?(AcaEntities::MagiMedicaid::Application)
            Success(cv3_application)
          else
            Failure('Invalid input, must be an instance of AcaEntities::MagiMedicaid::Application')
          end
        end

        def find_family(cv3_application)
          application = ::FinancialAssistance::Application.by_hbx_id(cv3_application.hbx_id).first

          if application.present?
            family = application.family
            if family.present?
              Success(family)
            else
              Failure("Family not found for application with hbx_id: #{cv3_application.hbx_id}")
            end
          else
            Failure("FinancialAssistance::Application is not found with given hbx_id: #{cv3_application.hbx_id}")
          end
        end

        def construct_payload(cv3_application)
          payload = {
            family_id: @family.id,
            application_hbx_id: cv3_application.hbx_id,
            effective_date: cv3_application.aptc_effective_date,
            households: households(cv3_application)
          }

          Success(payload)
        end

        def households(cv3_application)
          aptc_tax_households = cv3_application.tax_households.select do |thh|
            thh.aptc_members_aged_below_19(cv3_application.aptc_effective_date).present?
          end

          aptc_tax_households.collect do |tax_household|
            { household_id: tax_household.hbx_id, members: members(tax_household.aptc_csr_eligible_members) }
          end
        end

        def members(aptc_csr_eligible_members)
          aptc_csr_eligible_members.collect do |thhm|
            family_member = @family.find_family_member_by_person_hbx_id(thhm.applicant_reference&.person_hbx_id)
            next thhm if family_member.blank?

            { family_member_id: family_member&.id, relationship_with_primary: family_member.primary_relationship }
          end
        end
      end
    end
  end
end
