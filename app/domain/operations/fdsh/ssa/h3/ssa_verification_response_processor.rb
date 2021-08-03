# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ssa
      module H3
        # This class will update the person and consumer role based on response
        class SsaVerificationResponseProcessor
          send(:include, Dry::Monads[:result, :do, :try])
          include EventSource::Command

          def call(params)
            person = yield find_person(params[:person_hbx_id])
            consumer_role = yield store_response_and_get_consumer_role(person, params[:response])
            updated_consumer_role = yield update_consumer_role(consumer_role, params[:response])

            Success(updated_consumer_role)
          end

          private

          def find_person(person_hbx_id)
            person = Person.where(hbx_id:person_hbx_id).first
            person.present? ? Success(person) : Failure("person not found with hbx_id: #{person_hbx_id}")
          end

          def update_consumer_role(consumer_role, response)
            args = OpenStruct.new
            args.determined_at = Time.now
            args.vlp_authority = 'fdsh_ssa'
            response_code = response.dig(:ResponseMetadata, :ResponseCode)
            ssa_response = response.dig(:SSACompositeIndividualResponses, 0, :SSAResponse)

            if response_code == "HS000000" && ssa_response.present?
              ssn_verification_indicator = ssa_response[:SSNVerificationIndicator]
              citizenship_verification_indicator = ssa_response[:PersonUSCitizenIndicator]

              if ssn_verification_indicator && citizenship_verification_indicator
                args.citizenship_result = ::ConsumerRole::US_CITIZEN_STATUS
                consumer_role.ssn_valid_citizenship_valid!(args)
              elsif ssn_verification_indicator && !citizenship_verification_indicator
                args.citizenship_result = ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
                consumer_role.ssn_valid_citizenship_invalid!(args)
              elsif !ssn_verification_indicator
                consumer_role.ssn_invalid!(args)
              end
            else
              consumer_role.ssn_invalid!(args) if consumer_role.may_ssn_invalid?
            end
            consumer_role.save
            Success(consumer_role)
          end

          def get_citizen_status(status)
            return "us_citizen" if status.eql? "UNITED STATES CITIZEN"
            return "lawful_permanent_resident" if status.eql? "LAWFUL PERMANENT RESIDENT - EMPLOYMENT AUTHORIZED"
            return "alien_lawfully_present" if ::ConsumerRole::VLP_RESPONSE_ALIEN_LEGAL_STATES.include?(status)
          end

          def store_response_and_get_consumer_role(person, initial_response)
            consumer_role = person.consumer_role
            return Failure("No Consumer role found for person with hbx_id: #{person_hbx_id}") unless consumer_role
            event_response_record = EventResponse.new({received_at: Time.now, body: initial_response.to_h.to_json})
            consumer_role.lawful_presence_determination.ssa_responses << event_response_record
            person.verification_types.active.reject{|type| [VerificationType::LOCATION_RESIDENCY, "American Indian Status", "Immigration status"].include? type.type_name}.each do |type|
              type.add_type_history_element(action: "FDSH SSA Hub Response",
                                            modifier: "external Hub",
                                            update_reason: "Hub response",
                                            event_response_record_id: event_response_record.id)
            end

            consumer_role.save
            Success(consumer_role)
          end
        end
      end
    end
  end
end
