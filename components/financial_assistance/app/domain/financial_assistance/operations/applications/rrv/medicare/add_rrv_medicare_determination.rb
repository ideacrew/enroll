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
            include Dry::Monads[:result, :do]

            # @param [Hash] opts The options to add rrv medicare determination to applicants
            # @option opts [Hash] :application_response_payload ::AcaEntities::MagiMedicaid::Application params
            # @return [Dry::Monads::Result]
            def call(params)
              application_entity = yield initialize_application_entity(params[:payload])
              application = yield find_application(application_entity)
              result = yield update_applicant(application_entity, application)

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

            def update_applicant(response_app_entity, application)
              response_app_entity.applicants.each do |response_applicant_entity|
                applicant = find_matching_applicant(application, response_applicant_entity)
                update_applicant_verifications(applicant, response_applicant_entity)
              end
              Success('Successfully updated Applicant with evidences and verifications')
            end

            def find_matching_applicant(application, res_applicant_entity)
              application.applicants.detect do |applicant|
                applicant.person_hbx_id == res_applicant_entity.person_hbx_id
              end
            end

            def update_applicant_verifications(applicant, response_applicant_entity)
              response_esi_evidence = response_applicant_entity.evidences.detect{|evi| evi.key == :non_esi_mec}

              applicant_esi_evidence = applicant.evidences.by_name(:non_esi_mec).first

              applicant_esi_evidence.update_attributes(eligibility_status: response_esi_evidence.eligibility_status) if ["outstanding"].include?(response_esi_evidence.eligibility_status)

              if response_esi_evidence.eligibility_results.present?
                response_esi_evidence.eligibility_results.each do |eligibility_result|
                  applicant_esi_evidence.eligibility_results << FinancialAssistance::EligibilityResult.new(eligibility_result.to_h)
                end
              end
              applicant.save!

              Success(applicant)
            end
          end
        end
      end
    end
  end
end
