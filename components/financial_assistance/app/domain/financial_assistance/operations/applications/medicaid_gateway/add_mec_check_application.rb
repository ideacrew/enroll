# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # This Operation adds the MEC Check to the Application(persistence object)
        # Operation receives the MEC Check results
        class AddMecCheckApplication
          include Dry::Monads[:result, :do]

          # @param [Hash] opts The options to add eligibility determination to Application(persistence object)
          # @return [Dry::Monads::Result]
          def call(params)                    
            application = yield find_application(params[:application_identifier])
            people = yield get_people(application)
            application = yield update_application(application)            
            result = yield update_people(people, params)

            Success(result)
          end

          private

          def get_people(application)
            person_ids = application.applicants.map(&:person_hbx_id)
            people = person_ids.map do |id|
                person = find_person(id)
                return person if person.failure?
                person.value! 
            end
            Success(people)
          end

          def find_person(person_id)            
            person = ::Person.find_by(hbx_id: person_id)

            Success(person)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Person with ID #{person_id}.")
          end

          def update_people(people, params)
            people.each do |person|
                response = params[:applicant_responses][person.hbx_id]
                result = update_person(person, response)
                return result if result.failure?                
            end
            Success("MEC check added for all applicants.")
          end

          def update_person(person, response)
            result = person.update_attributes!({
                                        mec_check_response: response,
                                        mec_check_date: DateTime.now
                                      })
            result ? Success("Updated person MEC check.") : Failure("Failed to update person MEC check.")
          end

          def find_application(application_id)
            application = FinancialAssistance::Application.find(application_id)

            Success(application)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Application with ID #{application_id}.")
          end

          def update_application(application)
            application.assign_attributes({ has_mec_check_response: true })
            if application.save
              Success(application)
            else
              Failure("Unable to update application with hbx_id: #{application.hbx_id}.")
            end
          end          
        end
      end
    end
  end
end
