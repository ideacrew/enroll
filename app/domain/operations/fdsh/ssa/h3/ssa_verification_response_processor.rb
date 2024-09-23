# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ssa
      module H3
        # This class will update the person and consumer role based on response
        class SsaVerificationResponseProcessor
          include ::Operations::Transmittable::TransmittableUtils

          def call(params)
            transmittable_objects = yield find_transmittable(params)
            person = yield find_person(params[:person_hbx_id], transmittable_objects[:subject])
            consumer_role = yield store_response_and_get_consumer_role(person, params[:response])
            updated_consumer_role = yield update_consumer_role(consumer_role, params[:response])
            _updated_transmittable_objects = yield record_results(transmittable_objects)
            Success(updated_consumer_role)
          end

          private

          def find_transmittable(params)
            return Success({}) unless EnrollRegistry[:ssa_h3].setting(:use_transmittable).item
            person = find_person(params[:person_hbx_id], nil)
            subject = person.value!&.to_global_id&.uri if person.success?
            result = Operations::Transmittable::GenerateResponseObjects.new.call({job_id: params[:metadata][:headers]["job_id"],
                                                                                  key: :ssa_verification_response,
                                                                                  payload: params[:response],
                                                                                  correlation_id: params[:person_hbx_id],
                                                                                  subject_gid: subject})
            return result if result.success?
            add_errors(:find_transmittable, "Failed to create response objects due to #{result.failure}", { job: @job, transmission: @transmission })
            status_result = update_status(result.failure, :failed, { job: @job })
            return status_result if status_result.failure?
            result
          end

          def find_person(person_hbx_id, subject)
            return Success(subject) if subject
            person = Person.where(hbx_id: person_hbx_id).first
            person.present? ? Success(person) : Failure("person not found with hbx_id: #{person_hbx_id}")
          end

          def update_consumer_role(consumer_role, response)
            args = OpenStruct.new
            args.determined_at = Time.now
            args.vlp_authority = 'ssa'
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
            elsif consumer_role.may_ssn_invalid?
              consumer_role.ssn_invalid!(args)
            end
            consumer_role.save!
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
            non_ssa_types = [VerificationType::LOCATION_RESIDENCY, "American Indian Status", "Immigration status"]

            person.verification_types.without_alive_status_type.active.reject{|type| non_ssa_types.include? type.type_name}.each do |type|
              type.add_type_history_element(action: "FDSH SSA Hub Response",
                                            modifier: "external Hub",
                                            update_reason: "Hub response",
                                            event_response_record_id: event_response_record.id)
            end

            consumer_role.save
            Success(consumer_role)
          end

          def record_results(transmittable_objects)
            return Success() unless EnrollRegistry[:ssa_h3].setting(:use_transmittable).item
            update_status("Processed SSA response", :succeeded, transmittable_objects.except(:subject))
          end
        end
      end
    end
  end
end
