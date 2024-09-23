# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Vlp
      module H92
        # This class will update the person and consumer role based on response
        class InitialResponseProcessor
          include Dry::Monads[:do, :result, :try]
          include EventSource::Command

          def call(params)
            person = yield find_person(params[:person_hbx_id])
            consumer_role = yield store_response_and_get_consumer_role(person, params[:response])
            updated_consumer_role = yield update_consumer_role(consumer_role, params[:response])

            Success(updated_consumer_role)
          end

          private

          def find_person(person_hbx_id)
            person = Person.where(hbx_id: person_hbx_id).first
            person.present? ? Success(person) : Failure("person not found with hbx_id: #{person_hbx_id}")
          end

          # rubocop:disable Metrics/BlockNesting
          def update_consumer_role(consumer_role, response)
            args = OpenStruct.new
            args.determined_at = Time.now
            args.vlp_authority = 'dhs'
            if response.dig(:ResponseMetadata, :ResponseCode) == "HS000000"
              individual_response = response.dig(:InitialVerificationResponseSet, :InitialVerificationIndividualResponses).first
              args.qualified_non_citizenship_result = individual_response.dig(:InitialVerificationIndividualResponseSet, :QualifiedNonCitizenCode)
              if individual_response.dig(:ResponseMetadata, :ResponseCode) == "HS000000"
                args.qualified_non_citizenship_result = parse_qnc_code(consumer_role, individual_response)
                if ['Y', 'X'].include?(individual_response[:LawfulPresenceVerifiedCode])
                  args.citizenship_result = get_citizen_status(individual_response.dig(:InitialVerificationIndividualResponseSet, :EligStatementTxt))
                  consumer_role.pass_dhs!(args) if consumer_role.may_pass_dhs?
                else
                  args.citizenship_result = ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
                  consumer_role.fail_dhs!(args) if consumer_role.may_fail_dhs?
                end
              end
            elsif consumer_role.may_fail_dhs?
              consumer_role.fail_dhs!(args)
            end
            consumer_role.save!
            Success(consumer_role)
          end
          # rubocop:enable Metrics/BlockNesting

          def get_citizen_status(status)
            return "us_citizen" if status.eql? "UNITED STATES CITIZEN"
            return "lawful_permanent_resident" if status.eql? "LAWFUL PERMANENT RESIDENT - EMPLOYMENT AUTHORIZED"
            return "alien_lawfully_present" if ::ConsumerRole::VLP_RESPONSE_ALIEN_LEGAL_STATES.include?(status)
          end

          def store_response_and_get_consumer_role(person, initial_response)
            consumer_role = person.consumer_role
            return Failure("No Consumer role found for person with hbx_id: #{person.hbx_id}") unless consumer_role
            store_five_year_bar_information(consumer_role, initial_response)

            event_response_record = EventResponse.new({received_at: Time.now, body: initial_response.to_h.to_json})
            consumer_role.lawful_presence_determination.vlp_responses << event_response_record
            if person.verification_types.active.map(&:type_name).include? "Citizenship"
              type_name = "Citizenship"
            elsif person.verification_types.active.map(&:type_name).include? "Immigration status"
              type_name = "Immigration status"
            end
            type = person.verification_types.active.where(type_name: type_name).first
            type&.add_type_history_element(action: "FDSH Hub response",
                                           modifier: "external Hub",
                                           update_reason: "Hub response",
                                           event_response_record_id: event_response_record.id)

            consumer_role.save
            Success(consumer_role)
          end

          def store_five_year_bar_information(consumer_role, response)
            individual_response = response.dig(:InitialVerificationResponseSet, :InitialVerificationIndividualResponses).first[:InitialVerificationIndividualResponseSet]
            consumer_role.five_year_bar_applies = vlp_response_code_to_boolean(individual_response[:FiveYearBarApplyCode]) if individual_response.key?(:FiveYearBarApplyCode)
            consumer_role.five_year_bar_met = vlp_response_code_to_boolean(individual_response[:FiveYearBarMetCode]) if individual_response.key?(:FiveYearBarMetCode)
            consumer_role.person.save! if individual_response[:FiveYearBarApplyCode].present? || individual_response[:FiveYearBarMetCode].present?
          rescue StandardError => e
            Rails.logger.error "Failed to update Consumer Role with Five Year Bar information, message: #{e.message}"
          end

          def parse_qnc_code(consumer_role, individual_response)
            qnc_code = individual_response.dig(:InitialVerificationIndividualResponseSet, :QualifiedNonCitizenCode)

            case qnc_code&.upcase
            when 'Y', 'P'
              'Y'
            when 'X'
              consumer_role.us_citizen ? 'N' : 'Y'
            else
              'N'
            end
          end

          def vlp_response_code_to_boolean(code_value)
            case code_value
            when 'P', nil, 'Y' then true
            when 'X', 'N' then false
            end
          end
        end
      end
    end
  end
end
