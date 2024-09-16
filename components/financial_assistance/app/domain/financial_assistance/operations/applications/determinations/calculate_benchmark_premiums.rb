# frozen_string_literal: true

module FinancialAssistance
  module Operations
    module Applications
      module Determinations
        # Class to calculate benchmark premiums for a given application
        class CalculateBenchmarkPremiums
          include Dry::Monads[:do, :result]

          # Main method to calculate benchmark premiums
          #
          # @param [Hash] params the parameters containing the application
          # @option params [FinancialAssistance::Application] :application the application object
          # @return [Dry::Monads::Result] the result monad containing benchmark premiums or failure message
          def call(params)
            application         = yield validate(params)
            family              = yield fetch_family(application)
            applicant_hbx_ids   = yield fetch_applicant_hbx_ids(application)
            effective_date      = yield fetch_effective_date(application)
            benchmark_premiums  = yield fetch_benchmark_premiums(applicant_hbx_ids, effective_date, family)

            Success(benchmark_premiums)
          end

          private

          # Validates the input parameters
          #
          # @param [Hash] params the parameters containing the application
          # @return [Dry::Monads::Result] the result monad containing the application or failure message
          def validate(params)
            return Success(params[:application]) if params[:application].is_a?(::FinancialAssistance::Application)

            Failure("Invalid application object. Expected FinancialAssistance::Application, got #{params[:application].class}")
          end

          # Fetches the family associated with the application
          #
          # @param [FinancialAssistance::Application] application the application object
          # @return [Dry::Monads::Result] the result monad containing the family or failure message
          def fetch_family(application)
            family = application.family
            return Success(family) if family.present?

            Failure("Family not found for application with id: #{application.id}")
          end

          # Fetches the applicant HBX IDs from the application
          #
          # @param [FinancialAssistance::Application] application the application object
          # @return [Dry::Monads::Result] the result monad containing the applicant HBX IDs or failure message
          def fetch_applicant_hbx_ids(application)
            hbx_ids = application.applicants.pluck(:person_hbx_id)
            return Success(hbx_ids) if hbx_ids.present?

            Failure("No applicants found for application with id: #{application.id}")
          end

          # Fetches the effective date from the application
          #
          # @param [FinancialAssistance::Application] application the application object
          # @return [Dry::Monads::Result] the result monad containing the effective date or failure message
          def fetch_effective_date(application)
            effective_date = application.effective_date
            return Success(effective_date) if effective_date.present?

            Failure("Effective date not found for application with id: #{application.id}")
          end

          # Fetches the benchmark premiums for the given applicant HBX IDs, effective date, and family
          #
          # @param [Array<String>] applicant_hbx_ids the applicant HBX IDs
          # @param [Date] effective_date the effective date
          # @param [Family] family the family object
          # @return [Dry::Monads::Result] the result monad containing the benchmark premiums or failure message
          def fetch_benchmark_premiums(applicant_hbx_ids, effective_date, family)
            premiums = ::Operations::Products::Fetch.new.call({ effective_date: effective_date, family: family })
            return build_zero_member_premiums(applicant_hbx_ids) if premiums.failure?

            slcsp_info = ::Operations::Products::FetchSlcsp.new.call(member_silver_product_premiums: premiums.success)
            return build_zero_member_premiums(applicant_hbx_ids) if slcsp_info.failure?

            lcsp_info = ::Operations::Products::FetchLcsp.new.call(member_silver_product_premiums: premiums.success)
            return build_zero_member_premiums(applicant_hbx_ids) if lcsp_info.failure?

            Success(construct_benchmark_premiums(applicant_hbx_ids, slcsp_info.success, lcsp_info.success))
          end

          # Constructs the benchmark premiums for the given applicant HBX IDs, SLCSP info, and LCSP info
          #
          # @param [Array<String>] applicant_hbx_ids the applicant HBX IDs
          # @param [Hash] slcsp_info the SLCSP information
          # @param [Hash] lcsp_info the LCSP information
          # @return [Hash] the constructed benchmark premiums
          def construct_benchmark_premiums(applicant_hbx_ids, slcsp_info, lcsp_info)
            applicant_hbx_ids.inject({}) do |premiums, applicant_hbx_id|
              if slcsp_info[applicant_hbx_id].present?
                premiums[:health_only_slcsp_premiums] ||= []
                slcsp_premium = slcsp_info[applicant_hbx_id][:health_only_slcsp_premiums]
                premiums[:health_only_slcsp_premiums] << { member_identifier: slcsp_premium[:member_identifier], monthly_premium: slcsp_premium[:monthly_premium] }
              end

              if lcsp_info[applicant_hbx_id].present?
                premiums[:health_only_lcsp_premiums] ||= []
                lcsp_premium = lcsp_info[applicant_hbx_id][:health_only_lcsp_premiums]
                premiums[:health_only_lcsp_premiums] << { member_identifier: lcsp_premium[:member_identifier], monthly_premium: lcsp_premium[:monthly_premium] }
              end

              premiums
            end
          end

          # Builds zero member premiums for both SLCSP and LCSP when there is a failure monad
          #
          # @param [Array<String>] applicant_hbx_ids the applicant HBX IDs
          # @return [Dry::Monads::Result] the result monad containing zero member premiums
          def build_zero_member_premiums(applicant_hbx_ids)
            member_premiums = applicant_hbx_ids.collect do |applicant_hbx_id|
              { member_identifier: applicant_hbx_id, monthly_premium: 0.0 }
            end.compact

            Success({ health_only_lcsp_premiums: member_premiums, health_only_slcsp_premiums: member_premiums })
          end
        end
      end
    end
  end
end
