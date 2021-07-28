# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Vlp
      module H92
        # This class will update the person and consumer role based on response
        class InitialResponseProcessor
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
            args.vlp_authority = 'fdsh'
            if response.dig(:ResponseMetadata, :ResponseCode) == "HS000000"
              individual_response = response.dig(:InitialVerificationResponseSet, :InitialVerificationIndividualResponses).first
              args.qualified_non_citizenship_result = individual_response.dig(:InitialVerificationIndividualResponseSet, :QualifiedNonCitizenCode)
              if individual_response.dig(:ResponseMetadata, :ResponseCode) == "HS000000"
                if individual_response[:LawfulPresenceVerifiedCode] == "Y"
                  args.citizenship_result = get_citizen_status(individual_response.dig(:InitialVerificationIndividualResponseSet, :EligStatementTxt))
                  consumer_role.pass_dhs!(args) if consumer_role.may_pass_dhs?
                else
                  args.citizenship_result = ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
                  consumer_role.fail_dhs!(args) if consumer_role.fail_dhs?
                end
              end
            else
              consumer_role.fail_dhs!(args) if consumer_role.fail_dhs?
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
            consumer_role.lawful_presence_determination.vlp_responses << event_response_record
            if person.verification_types.active.map(&:type_name).include? "Citizenship"
              type_name = "Citizenship"
            elsif person.verification_types.active.map(&:type_name).include? "Immigration status"
              type_name = "Immigration status"
            end
            type = person.verification_types.active.where(type_name:type_name).first
            if type
              type.add_type_history_element(action: "FDSH Hub response",
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
