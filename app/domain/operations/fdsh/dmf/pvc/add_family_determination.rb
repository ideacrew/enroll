# frozen_string_literal: true

# {encrypted_family_payload: encrypted_payload, job_id: job_id}
module Operations
  module Fdsh
    module Dmf
      module Pvc
        # This operation is used to add family determination
        class AddFamilyDetermination
          include Dry::Monads[:result]
          include Dry::Monads::Do.for(:call)
          include EventSource::Logging
          include ::Operations::Transmittable::TransmittableUtils

          def call(params)
            encrypted_family_payload, job_id, @family_hbx_id = yield validate(params)
            @job = yield find_job(job_id)
            @family = yield find_family(@family_hbx_id)
            values = yield construct_base_response_values
            @transmission = yield create_response_transmission(values.merge(job: @job), {job: @job})
            @transaction = yield create_response_transaction(values.merge(transmission: @transmission, subject: @family), {job: @job, transmission: @transmission})
            decrypted_family_payload = yield decrypt_payload(encrypted_family_payload)
            parsed_family_payload = yield parse_json_payload(decrypted_family_payload)
            @entity_family = yield validate_family(parsed_family_payload)
            yield add_determination
            trigger_family_determination(@family)

            Success("Successfully Added Family Determination")
          end

          private

          def validate(params)
            errors = []
            errors << 'encrypted_family_payload ref missing' unless params[:encrypted_family_payload]
            errors << 'job_id ref missing' unless params[:job_id]
            errors << 'family_hbx_id ref missing' unless params[:family_hbx_id]
            errors.empty? ? Success([params[:encrypted_family_payload], params[:job_id], params[:family_hbx_id].to_s]) : Failure(errors)
          end

          def find_family(_family_hbx_id)
            family = Family.find_by(hbx_assigned_id: @family_hbx_id)
            if family.present?
              Success(family)
            else
              Failure("Could not find Family with hbx_id #{@family_hbx_id}")
            end
          end

          def decrypt_payload(encrypted_family_payload)
            result = AcaEntities::Operations::Encryption::Decrypt.new.call(value: encrypted_family_payload)


            if result.success?
              Success(result.value!)
            else
              add_errors(
                :decrypt_payload,
                "Failed to decrypt family payload due to #{result.failure}",
                { transmission: @transmission, transaction: @transaction}
              )
              Failure("Failed to decrypt payload #{@family_hbx_id}")
            end
          end

          def parse_json_payload(decrypted_family_payload)
            Success(JSON.parse(decrypted_family_payload, symbolize_names: true))
          rescue JSON::ParserError => e
            add_errors(
              :parse_json_payload,
              "Failed to parse family json payload due to #{e}",
              { transmission: @transmission, transaction: @transaction}
            )

            Failure("Failed to parse JSON payload for family #{@family_hbx_id}")
          end

          def validate_family(parsed_family_payload)
            result = AcaEntities::Operations::CreateFamily.new.call(parsed_family_payload)

            if result.success?
              Success(result.value!)
            else
              add_errors(
                :validate_family,
                "validation failed for family payload due to #{result.failure}",
                { transmission: @transmission, transaction: @transaction}
              )
              Failure("Validation failed for family #{@family_hbx_id}")
            end
          end

          def construct_base_response_values
            values = {
              key: :dmf_determination_response,
              title: "#{@job.title} Response",
              description: "#{@job.description}: dmf response for family with hbx_id #{@family_hbx_id}",
              correlation_id: @family_hbx_id,
              transmission_id: @family_hbx_id,
              transaction_id: @family_hbx_id,
              started_at: DateTime.now,
              publish_on: DateTime.now,
              event: 'initial',
              state_key: :initial
            }

            Success(values)
          end

          def add_determination
            entity_members = @entity_family.family_members

            entity_members.each do |entity_member|
              process_member(entity_member)
            end

            update_status("DMF Family Determination successfully saved", :succeeded, { transmission: @transmission, transaction: @transaction })
            Success("Successfully added determination for family #{@family_hbx_id}")
          rescue StandardError => e
            add_errors(
              :add_determination,
              "unable to update Alive Status Verification Type for family : #{@family_hbx_id} , error: #{e}",
              { transmission: @transmission, transaction: @transaction}
            )

            Failure("unable to update Alive Status Verification Type for family : #{@family_hbx_id} , error: #{e}")
          end

          def process_member(entity_member)
            person_entity = entity_member.person
            alive_status_entity = person_entity.person_demographics.alive_status
            entity_verification_types = person_entity.verification_types
            alive_status_verification_entity = entity_verification_types.detect { |vt| vt.type_name == 'Alive Status' }
            entity_validation_status = alive_status_verification_entity.validation_status
            return unless ['attested', 'outstanding'].include?(entity_validation_status)

            person = Person.by_hbx_id(person_entity.hbx_id).first
            alive_status_verification_type = person.alive_status

            if alive_status_verification_type.present?
              add_member_determination(alive_status_verification_type, entity_validation_status, person, alive_status_entity)
            else
              add_errors(
                :add_determination,
                "Alive status verification type not present for  member hbx_id: #{person.hbx_id}",
                { transmission: @transmission, transaction: @transaction}
              )
            end
          end

          def add_member_determination(alive_status_verification_type, entity_validation_status, person, alive_status_entity)
            from_validation_status = alive_status_verification_type.validation_status

            case entity_validation_status
            when 'attested'
              alive_status_verification_type.update_attributes(validation_status: 'attested')
              person.demographics_group.alive_status.update(is_deceased: false, date_of_death: alive_status_entity.date_of_death)
            when 'outstanding'
              is_enrolled = person.families.any? { |f| f.person_has_an_active_enrollment?(person) }
              update_validation_status(alive_status_verification_type, (is_enrolled ? 'outstanding' : 'negative_response_received'))
              person.demographics_group.alive_status.update(is_deceased: true, date_of_death: alive_status_entity.date_of_death)
            end

            message = "DMF Determination response for Family with hbx_id #{@family_hbx_id} received successfully"
            alive_status_verification_type.reload

            event_response_record = EventResponse.create({received_at: Time.now, body: {job_id: @job.job_id, family_hbx_id: @family_hbx_id, death_confirmation_code: entity_validation_status, date_of_death: alive_status_entity.date_of_death}.to_json})
            alive_status_verification_type.add_type_history_element(action: "DMF Hub Response", modifier: "System", update_reason: message, from_validation_status: from_validation_status,
                                                                    to_validation_status: alive_status_verification_type.validation_status, event_response_record_id: event_response_record.id)
          end

          def update_validation_status(alive_status_verification_type, new_validation_status)
            verification_document_due = EnrollRegistry[:bulk_call_verification_due_in_days].item

            status = if alive_status_verification_type.validation_status == 'rejected'
                       'rejected'
                     else
                       new_validation_status
                     end
            attrs = {:validation_status => status, :due_date => (TimeKeeper.date_of_record + verification_document_due.days), :due_date_type => 'bulk_response_from_hub'}

            alive_status_verification_type.update_attributes(attrs)
          end

          def trigger_family_determination(family)
            ::Operations::Eligibilities::BuildFamilyDetermination.new.call(family: family, effective_date: TimeKeeper.date_of_record)
          end
        end
      end
    end
  end
end
