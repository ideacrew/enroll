# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  class UpdateDobSsn
    include Dry::Monads[:do, :result]

    def call(person_id:, params:, current_user:, ssn_require:)
      person = yield fetch_person(person_id)
      yield validate_if_person_can_update(person)
      update_person(person, params, current_user, ssn_require)
    end

    private

    def fetch_person(person_id)
      person = ::Person.where(_id: person_id).first
      person ? Success(person) : Failure([{person: ['Person not found']}, nil])
    end

    def validate_if_person_can_update(person)
      if person&.consumer_role&.vlp_documents.present?
        result = ::Operations::ValidateVlpDocument.new.call(person_id: person.id)
        result.failure? ? Failure([{person: [result.failure]}, nil]) : Success(true)
      else
        Success(true)
      end
    end

    def update_person(person, params, current_user, ssn_require)
      person.dob = Date.strptime(params[:jq_datepicker_ignore_person][:dob], '%m/%d/%Y').to_date
      if params[:person][:ssn].blank?
        if ssn_require
          dont_update_ssn = true
        else
          person.unset(:encrypted_ssn)
        end
      else
        person.ssn = params[:person][:ssn]
      end
      person.save!
      # Updates the no_ssn field to indicate no_ssn and also to trigger the Hub Calls
      person.update_attributes!({ no_ssn: '1' }) if person.encrypted_ssn.blank?
      CensusEmployee.update_census_employee_records(person, current_user)
      Success([nil, dont_update_ssn])
    rescue StandardError => e
      error_on_save = person.errors.messages
      error_on_save[:census_employee] = [e.summary] if person.errors.messages.blank? && e.present?
      Failure([error_on_save, dont_update_ssn])
    end
  end
end
