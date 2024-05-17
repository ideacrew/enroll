# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Rrv
        module Ifsv
          # This Operation determines applicants rrv ifsv eligibility
          # Operation receives the Application with renewal ifsv determination values
          class AddRrvIfsvDetermination
            include Dry::Monads[:do, :result]

            # @param [Hash] opts The options to add rrv ifsv determination to applicants
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

            def find_matching_applicant(application, res_applicant_entity)
              application.applicants.detect do |applicant|
                applicant.person_hbx_id == res_applicant_entity.person_hbx_id
              end
            end

            def update_applicant(response_app_entity, application)
              is_ifsv_eligible = response_app_entity.tax_households.first.is_ifsv_eligible
              status = is_ifsv_eligible ? "verified" : "outstanding"

              response_app_entity.applicants.each do |response_applicant_entity|
                applicant = find_matching_applicant(application, response_applicant_entity)
                if applicant.income_evidence.blank?
                  Rails.logger.error("Income Evidence not found for applicant with person_hbx_id: #{applicant.person_hbx_id} in application with hbx_id: #{application.hbx_id}")
                  next
                end
                update_applicant_evidence(applicant, status, response_applicant_entity)
              end
              Success('Successfully updated Applicant with evidence')
            end

            def update_applicant_evidence(applicant, status, response_applicant_entity)
              response_income_evidence = response_applicant_entity.income_evidence
              income_evidence = applicant.income_evidence

              case status
              when "verified"
                applicant.set_income_evidence_verified
              when "outstanding"
                applicant.set_evidence_outstanding(income_evidence)
              end

              response_income_evidence.request_results&.each do |request_result|
                income_evidence.request_results << Eligibilities::RequestResult.new(request_result.to_h.merge(action: "Hub Response"))
              end
              applicant.save!
            end
          end
        end
      end
    end
  end
end
