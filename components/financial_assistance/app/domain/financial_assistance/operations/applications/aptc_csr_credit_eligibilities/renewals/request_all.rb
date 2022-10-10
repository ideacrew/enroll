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
              family_ids = yield find_families(params[:renewal_year])
              family_ids = yield generate_renewal_events(params[:renewal_year], family_ids)

              Success(family_ids)
            end

            private

            def find_families(renewal_year)
              # Success(::Family.all_active_assistance_receiving_for_assistance_year(renewal_year.pred).all_enrollments.distinct(:id))

              family_ids = ::HbxEnrollment.enrolled.current_year.distinct(:family_id)
              determined_family_ids = ::FinancialAssistance::Application.by_year(renewal_year.pred).where(:family_id.in => family_ids).distinct(:family_id)

              Success(determined_family_ids)
            end

            # rubocop:disable Style/MultilineBlockChain
            def generate_renewal_events(renewal_year, family_ids)
              logger = Logger.new("#{Rails.root}/log/aptc_credit_eligibilities_request_all_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")

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
