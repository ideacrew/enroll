# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

# rubocop:disable Style/MultilineBlockChain

module FinancialAssistance
  module Operations
    module Applications
      module AptcCsrCreditEligibilities
        module Renewals
          # This Operation creates a new renewal_draft application from a given family identifier(BSON ID),
          # ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::Renew.new.call({ family_id: "617d5cafcd9621000a5cf7e5", renewal_year: 2023 })
          class Renew
            include Dry::Monads[:result, :do, :try]
            include EventSource::Command

            # @param [Hash] opts The options to generate renewal_draft application
            # @option opts [BSON::ObjectId] :family_id (required)
            # @option opts [Integer] :renewal_year (required)
            # @return [Dry::Monads::Result]
            def call(params)
              validated_params       = yield validate(params)
              latest_application     = yield find_latest_application(validated_params)
              renewal_draft_app      = yield renew_application(latest_application, validated_params)
              # result                 = yield generate_renewed_event(renewal_draft_app, validated_params[:renewal_year])

              Success(renewal_draft_app)
            end

            private

            def validate(params)
              return Failure('Missing family_id key') unless params.key?(:family_id)
              return Failure('Missing renewal_year key') unless params.key?(:renewal_year)
              return Failure("Cannot find family with input value: #{params[:family_id]} for key family_id") if ::Family.where(id: params[:family_id]).first.nil?
              return Failure("Invalid value: #{params[:renewal_year]} for key renewal_year, must be an Integer") if params[:renewal_year].nil? || !params[:renewal_year].is_a?(Integer)
              Success(params)
            end

            def find_latest_application(validated_params)
              applications_by_family = ::FinancialAssistance::Application.where(family_id: validated_params[:family_id])

              return Failure("Renewal application already created for #{validated_params}") if applications_by_family.by_year(validated_params[:renewal_year]).present?

              application = applications_by_family.by_year(validated_params[:renewal_year].pred).determined.created_asc.last

              if application&.eligible_for_renewal?
                Success(application)
              else
                Failure("Could not find any applications that are renewal eligible: #{validated_params}.")
              end
            rescue SystemStackError => e
              Failure("Critical Error: Unable to find application from database for family id: #{validated_params[:family_id]}.\n error_message: #{e.message} \n backtrace: #{e.backtrace.join("\n")}")
            end

            def renew_application(application, validated_params)
              application = create_renewal_draft_application(application, validated_params)

              return Failure("Unable to create renewal application - #{application.failure} with params: (#{validated_params})") if application.failure?

              application
            end

            # I agree + 5 years
            ### Copy application via UI: I agree, 5 years to renew
            ### Copy application via renewal - I agree, -1 years to renew
            # I disagree + x years
            ### Copy application via UI: I disagree + x years
            ### Copy application via renewal - I disagree + (x years - 1)
            # I agree + <5 years
            ### Copy application via UI: I agree, 5 years to renew
            ### Copy application via renewal - I agree + (x years -1)

            # If years to renew is 0, set to income_verification_extension_required
            def create_renewal_draft_application(application, validated_params)
              Try() do
                ::FinancialAssistance::Operations::Applications::Copy.new
              end.bind do |renewal_application_factory|
                copied_result = renewal_application_factory.call(application_id: application.id)
                return Failure(copied_result.failure[:detailed_error_message]) if copied_result.failure?

                renewal_application = copied_result.success
                family_members_changed = renewal_application_factory.family_members_changed
                relationships_changed = renewal_application_factory.relationships_changed
                calculated_renewal_base_year = calculate_renewal_base_year(application)
                renewal_application.assign_attributes(
                  aasm_state: find_aasm_state(
                    application,
                    family_members_changed,
                    renewal_application,
                    relationships_changed
                  ),
                  assistance_year: validated_params[:renewal_year],
                  years_to_renew: calculate_years_to_renew(application),
                  renewal_base_year: calculated_renewal_base_year,
                  predecessor_id: application.id,
                  effective_date: Date.new(validated_params[:renewal_year])
                )

                renewal_application.full_medicaid_determination = application.full_medicaid_determination if full_medicaid_determination_feature_enabled?

                renewal_application.save
                if renewal_application.renewal_draft?
                  Success(renewal_application)
                else
                  Failure("Renewal Application: (#{renewal_application.hbx_id}) failed with aasm_state: (#{renewal_application.aasm_state}), because: (#{@failure_reason || 'Unknown'})")
                end
              end.to_result
            end

            def full_medicaid_determination_feature_enabled?
              feature = FinancialAssistanceRegistry[:full_medicaid_determination_step]
              feature.enabled? && feature.settings(:annual_eligibility_redetermination).item
            end

            def find_aasm_state(application, family_members_changed, renew_application, relationships_changed)
              if application.years_to_renew == 0 || application.years_to_renew.nil?
                @failure_reason = 'years_to_renew is 0 or nil'
                'income_verification_extension_required'
              elsif family_members_changed
                @failure_reason = 'family_members_changed'
                'applicants_update_required'
              elsif missing_relationships?(relationships_changed, renew_application)
                @failure_reason = 'missing_relationships'
                'applicants_update_required'
              else
                'renewal_draft'
              end
            end

            def missing_relationships?(relationships_changed, renew_application)
              relationships_changed && !renew_application.relationships_complete?
            end

            def calculate_years_to_renew(application)
              if application.years_to_renew.present? && application.years_to_renew > 0
                application.years_to_renew.to_i - 1
              else
                application.years_to_renew || 0
              end
            end

            def calculate_renewal_base_year(application)
              return application.renewal_base_year if application.renewal_base_year.present?
              application.calculate_renewal_base_year
            end

            def generate_renewed_event(application, renewal_year)
              params = { payload: { application_id: application.id.to_s, renewal_year: renewal_year }, event_name: 'renewed' }

              Try do
                ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::PublishRenewalRequest.new.call(params)
              end.bind do |result|
                if result.success?
                  Success("#{result.success} for application id: #{application.id}")
                else
                  Failure(result.failure)
                end
              end
            end

          end
        end
      end
    end
  end
end
# rubocop:enable Style/MultilineBlockChain
