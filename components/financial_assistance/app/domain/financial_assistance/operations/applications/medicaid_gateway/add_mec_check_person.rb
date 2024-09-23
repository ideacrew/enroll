# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # This Operation adds the MEC Check to the Person(persistence object)
        # Operation receives the MEC Check results
        class AddMecCheckPerson
          include Dry::Monads[:do, :result]

          # @param [Hash] opts The options to add MEC check to Person(persistence object)
          # @return [Dry::Monads::Result]
          def call(params)
            person_id = params[:applicant_responses].keys.first
            response = params[:applicant_responses][person_id]
            person = yield find_person(person_id)
            result = yield update_person(person, response)

            Success(result)
          end

          private

          def find_person(person_id)
            person = ::Person.find_by(hbx_id: person_id)

            Success(person)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Person with ID #{person_id}.")
          end

          def update_person(person, response)
            person.update_attributes!({
                                        mec_check_response: response,
                                        mec_check_date: DateTime.now
                                      })
            Success("Updated person.")
          end
        end
      end
    end
  end
end
