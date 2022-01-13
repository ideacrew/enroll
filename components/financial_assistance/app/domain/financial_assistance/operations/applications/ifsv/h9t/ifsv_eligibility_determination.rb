# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Ifsv
        module H9t
          # This Operation determines applicants ifsv eligibility
          # Operation receives the Application with ifsv determination values
          class IfsvEligibilityDetermination
            include Dry::Monads[:result, :do]

            # @param [Hash] opts The options to add ifsv determination to applicants
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
              is_ifsv_eligible = response_app_entity.tax_households.first.is_ifsv_eligible
              status = is_ifsv_eligible ? "verified" : "outstanding"

              application.applicants.each do |applicant|
                next unless applicant.income_evidence.present?
                update_applicant_evidence(applicant, status)
              end
              Success('Successfully updated Applicant with evidence')
            end

            def update_applicant_evidence(applicant, status)
              income_evidence = applicant.income_evidence
              case status
              when "verified"
                applicant.set_income_evidence_verified
              when "outstanding"
                applicant.set_evidence_outstanding(income_evidence)
              end

              Success(applicant)
            end
          end
        end
      end
    end
  end
end
