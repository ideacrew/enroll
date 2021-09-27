# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    module SugarCrm
      # Class for publishing the results of updated families to Sugar CRM, if enabled
      class PublishFamily
        send(:include, Dry::Monads[:result, :do])
        include Dry::Monads[:result, :do]
        include EventSource::Command
        include EventSource::Logging

        # @param [ Family] instance fo family
        # @return Success result
        def call(family)
          transformed_family = yield construct_payload_hash(family)
          # payload_value = yield validate_payload(transformed_family)
          # payload_entity = yield create_payload_entity(payload_value)
          event = yield build_event(transformed_family)
          result = yield publish(event)
          Success(result)
        end

        private

        # CRM Gateway only needs a limited scope of data for
        # the initialization of Accounts/Contacts
        # Set them as blank arrays/hashes etc. here to skip optional Dry Validation in ACA Entities
        def simplify_crm_family_payload(transformed_family)
          transformed_family[:family_members].each do |fm_hash|
            unnecessary_document_keys = %i[
              vlp_documents
              ridp_documents
              verification_type_history_elements
              local_residency_responses
              local_residency_requests
            ]
            if fm_hash.dig(:person, :consumer_role)
              unnecessary_document_keys.each do |sym_value|
                fm_hash[:person][:consumer_role][sym_value] = []
              end
            end
            fm_hash[:person][:individual_market_transitions] = []
            fm_hash[:person][:verification_types] = []
          end
          transformed_family.except(
            :households,
            :renewal_consent_through_year,
            :special_enrollment_periods,
            :payment_transactions,
            :magi_medicaid_applications,
            :documents
          )
        end

        def construct_payload_hash(family)
          if family.is_a?(::Family)
            Operations::Transformers::FamilyTo::CrmCv3Family.new.call(family)
          else
            Failure("Invalid Family Object. Family class is: #{family.class}")
          end
        end

        def validate_payload(transformed_family)
          simplified_family_payload = simplify_crm_family_payload(transformed_family)
          result = AcaEntities::Contracts::Families::FamilyContract.new.call(simplified_family_payload)
          if result.success?
            result
          else
            hbx_id = transformed_family[:family_members].detect { |fm| fm[:is_primary_applicant] }[:hbx_id]
            Failure("Person with hbx_id #{hbx_id} is not valid due to #{result.errors.to_h}.")
          end
        end

        def create_payload_entity(payload_value)
          Success(AcaEntities::Families::Family.new(payload_value.to_h))
        end

        def build_event(payload)
          event('events.crm_gateway.families.family_update', attributes: payload.to_h)
        end

        def publish(event)
          event.publish
          Success("Successfully published payload to CRM Gateway.")
        end
      end
    end
  end
end
