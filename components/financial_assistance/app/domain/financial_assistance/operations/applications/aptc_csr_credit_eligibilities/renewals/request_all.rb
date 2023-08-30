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

            def call(params)
              family_ids = yield renewal_eligible_family_ids(params[:renewal_year])
              family_ids = yield generate_renewal_events(params[:renewal_year], family_ids)

              Success(family_ids)
            end

            private

            # Returns all family_ids where the family has a current enrollment and their most recent determined
            # fa application for the previous year is renewal eligible
            # @return [Array] family_ids
            def renewal_eligible_family_ids(renewal_year)
              family_ids = ::HbxEnrollment.individual_market.enrolled.current_year.distinct(:family_id)
              eligible_family_ids = ::FinancialAssistance::Application.by_year(renewal_year.pred).determined.where(:family_id.in => family_ids).group_by(&:family_id).select { |_family_id, group| group.max_by(&:created_at).eligible_for_renewal? }.keys
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
