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
            include Dry::Monads[:result, :do]

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

            def update_applicant(response_app_entity, application)
              is_ifsv_eligible = response_app_entity.tax_households.first.is_ifsv_eligible
              status = is_ifsv_eligible ? "verified" : "outstanding"

              application.eligibility_determinations.each do |ed|
                ed.applicants.each do |applicant|
                  next unless applicant.income_evidence.present?
                  update_applicant_evidence(applicant, status)
                end
              end
              Success('Successfully updated Applicant with evidence')
            end

            def update_applicant_evidence(applicant, status)
              evidence = applicant.income_evidence

              case status
              when "verified"
                evidence.move_to_verified!
                evidence.update!(is_satisfied: true)
              when "outstanding"
                evidence.move_to_outstanding!
                evidence.update!(verification_outstanding: true)
              end

              Success(applicant)
            end
          end
        end
      end
    end
  end
end
