# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module AptcCsrCreditEligibilities
        module Renewals
        # This class will query all distinct app_ids with renwal draft or submitted applications and trigger eligibility_determination renewal events
        # Syntax: FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::RequestAll.new.call({renewal_year: 2023})
        # Query renewal draft apps or submitted apps
          class RequestAll
            include Dry::Monads[:result, :do, :try]
            include EventSource::Command

            # Calls the method with the given parameters.
            #
            # @param params [Hash] the parameters for the method, including :renewal_year
            # @return [Success] the result containing the family IDs
            def call(params)
              @exclusion_family_ids = yield validate(params)
              family_ids = yield renewal_eligible_family_ids(params[:renewal_year])
              family_ids = yield generate_renewal_events(params[:renewal_year], family_ids)

              Success(family_ids)
            end

            private

            # Validates the given parameters.
            #
            # @param [Hash] params the parameters to validate
            # @option params [Array<String, BSON::ObjectId>] :exclusion_family_ids the family IDs to be excluded
            # @return [Success, Failure] the result of the validation
            def validate(params)
              return Failure('Invalid input. Params is expected to be a hash.') unless params.is_a?(Hash)
              return Failure('Missing key exclusion_family_ids. Must include exclusion_family_ids key with array as value.') if !params.key?(:exclusion_family_ids) || !params[:exclusion_family_ids].is_a?(Array)

              exclusion_family_ids = transform_ids_to_bson_ids(params[:exclusion_family_ids])
              return Failure("Unable to transform exclusion_family_ids: #{params[:exclusion_family_ids]} to BSON ObjectIds.") if exclusion_family_ids.blank? && params[:exclusion_family_ids].present?

              Success(exclusion_family_ids)
            end

            # Transforms the given family IDs to BSON ObjectIds.
            #
            # @param [Array<String, BSON::ObjectId>] exclusion_family_ids the family IDs to transform
            # @return [Array<BSON::ObjectId>] the transformed BSON ObjectIds
            def transform_ids_to_bson_ids(exclusion_family_ids)
              exclusion_family_ids.map do |family_id|
                if family_id.is_a?(BSON::ObjectId)
                  family_id
                else
                  BSON::ObjectId.from_string(family_id)
                end
              end
            rescue StandardError => e
              Rails.logger.error "Error raised when transforming IDs: #{exclusion_family_ids} with error: #{e.message}"
              []
            end

            # Returns all family_ids where the family has a current enrollment and their most recent determined
            # fa application for the previous year is renewal eligible
            #
            # @param renewal_year [Integer] the year for which renewal eligibility is being checked
            # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure] a Success object containing an array of eligible family_ids or a Failure object with an error message
            def renewal_eligible_family_ids(renewal_year)
              family_ids = ::HbxEnrollment.individual_market.enrolled.current_year.distinct(:family_id) - @exclusion_family_ids

              eligible_family_ids = ::FinancialAssistance::Application.by_year(
                renewal_year.pred
              ).determined.where(:family_id.in => family_ids).distinct(:family_id)

              Success(eligible_family_ids)
            rescue StandardError => e
              Failure("Failed to find renewal eligible family_ids, error: #{e}")
            end

            # rubocop:disable Style/MultilineBlockChain
            def generate_renewal_events(renewal_year, family_ids)
              logger = Logger.new("#{Rails.root}/log/aptc_credit_eligibilities_request_all.log")

              logger.info 'Started publish_generate_draft_renewals process'
              logger.info "Total number of applications with assistance_year: #{renewal_year.pred} are #{family_ids.count}"

              family_ids.each_with_index do |family_id, index|
                # EventSource Publishing
                params = { payload: { index: index, family_id: family_id.to_s, renewal_year: renewal_year }, event_name: 'renewal.requested' }

                Try do
                  ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::PublishRenewalRequest.new.call(params)
                end.bind do |result|
                  if result.success?
                    logger.info "Successfully Published for event renewal_requested, with params: #{params}"
                  else
                    logger.info "Failed to publish for event renewal_requested, with params: #{params}, failure: #{result.failure}"
                  end
                end
              end

              Success(family_ids)
            end
            # rubocop:enable Style/MultilineBlockChain
          end
        end
      end
    end
  end
end
