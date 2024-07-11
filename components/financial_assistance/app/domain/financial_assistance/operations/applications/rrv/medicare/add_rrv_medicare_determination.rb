# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Rrv
        module Medicare
          # This Operation determines applicants rrv medicare eligibility
          # Operation receives the Application with renewal medicare determination values
          class AddRrvMedicareDetermination
            include Dry::Monads[:do, :result]

            # @param [Hash] opts The options to add rrv medicare determination to applicants
            # @option opts [Hash] :application_response_payload ::AcaEntities::MagiMedicaid::Application params
            # @return [Dry::Monads::Result]
            def call(params)
              application_entity = yield initialize_application_entity(params[:payload])
              application = yield find_application(application_entity)
              result = yield update_applicant(application_entity, application, params[:applicant_identifier])

              Success(result)
            end

            private

            def initialize_application_entity(params)
              ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(params)
            end

            def find_application(application_entity)
              application = ::FinancialAssistance::Application.by_hbx_id(application_entity.hbx_id).first
              application.present? ? Success(application) : Failure("Could not find application with given hbx_id: #{application_entity.hbx_id}")
            end

            def update_applicant(response_app_entity, application, applicant_identifier)
              response_applicant = response_app_entity.applicants.detect {|applicant| applicant.person_hbx_id == applicant_identifier}
              applicant = application.applicants.where(person_hbx_id: applicant_identifier).first

              return Failure("applicant not found with #{applicant_identifier} for rrv Medicare") unless applicant
              return Failure("applicant not found in response with #{applicant_identifier} for rrv Medicare") unless response_applicant

              update_applicant_verifications(applicant, response_applicant)
              Success('Successfully updated Applicant with evidences and verifications')
            end

            def update_applicant_verifications(applicant, response_applicant_entity)
              response_non_esi_evidence = response_applicant_entity.non_esi_evidence
              applicant_non_esi_evidence = applicant.non_esi_evidence

              if applicant_non_esi_evidence.present?
                if response_non_esi_evidence.aasm_state == 'outstanding'
                  applicant.set_evidence_outstanding(applicant_non_esi_evidence)
                else
                  applicant.set_evidence_attested(applicant_non_esi_evidence)
                end

                if response_non_esi_evidence.request_results.present?
                  response_non_esi_evidence.request_results.each do |eligibility_result|
                    applicant_non_esi_evidence.request_results << Eligibilities::RequestResult.new(eligibility_result.to_h.merge(action: "Hub Response"))
                  end
                end
                applicant.save!
              end

              Success(applicant)
            end
          end
        end
      end
    end
  end
end
