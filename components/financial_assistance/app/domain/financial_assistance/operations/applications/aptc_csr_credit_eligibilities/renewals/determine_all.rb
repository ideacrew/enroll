# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module AptcCsrCreditEligibilities
        module Renewals
        # This class will query all distinct app_ids with renwal draft applications and trigger eligibility_determination renewal events
        # Syntax: FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::DetermineAll.new.call({renewal_year: 2023})
          class DetermineAll
            include Dry::Monads[:result, :do, :try]
            include EventSource::Command

            def call(params)
              renewal_year     = yield validate(params)
              app_ids          = yield find_renewal_draft(renewal_year)
              app_ids          = yield generate_determination_submission_events(params[:renewal_year], app_ids)

              Success(app_ids)
            end

            private

            def validate(params)
              return Failure('Missing renewal_year key') unless params.key?(:renewal_year)
              return Failure("Invalid value: #{params[:renewal_year]} for key renewal_year, must be an Integer") if params[:renewal_year].nil? || !params[:renewal_year].is_a?(Integer)
              Success(params[:renewal_year])
            end

            def find_renewal_draft(renewal_year)
              Success(::FinancialAssistance::Application.by_year(renewal_year).where(aasm_state: "renewal_draft").pluck(:id))
            end

            # rubocop:disable Style/MultilineBlockChain
            def generate_determination_submission_events(renewal_year, app_ids)
              logger = Logger.new("#{Rails.root}/log/aptc_credit_eligibilities_determine_all_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
              logger.info "Total number of applications with assistance_year: #{renewal_year.pred} are #{app_ids.count}"
              logger.info 'Started publishing renewal_events'

              app_ids.each_with_index do |app_id, index|
                params = { payload: { index: index, application_id: app_id.to_s, renewal_year: renewal_year}, event_name: 'determination_submission.requested' }

                Try do
                  ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::PublishRenewalRequest.new.call(params)
                end.bind do |result|
                  if result.success?
                    logger.info "Successfully Published for event determination_submission_requested, with params: #{params}"
                  else
                    logger.info "Failed to publish for event determination_submission_requested, with params: #{params}, failure: #{result.failure}"
                  end
                end
              end

              Success(app_ids)
            end
            # rubocop:enable Style/MultilineBlockChain
          end
        end
      end
    end
  end
end