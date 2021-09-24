# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # This class will query all distinct family_ids with renwal eligible applications and trigger renewal events
        class CreateApplicationRenewalRequest
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          def call(params)
            family_ids = yield find_families(params[:renewal_year])
            family_ids = yield generate_renewal_events(params[:renewal_year], family_ids)

            Success(family_ids)
          end

          private

          def find_families(renewal_year)
            Success(::FinancialAssistance::Application.by_year(renewal_year.pred).renewal_eligible.distinct(:family_id))
          end

          # rubocop:disable Style/MultilineBlockChain
          def generate_renewal_events(renewal_year, family_ids)
            logger = Logger.new("#{Rails.root}/log/fa_application_advance_day_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")

            logger.info 'Started publish_generate_draft_renewals process'
            logger.info "Total number of applications with assistance_year: #{renewal_year.pred} are #{family_ids.count}"
            family_ids.each_with_index do |family_id, index|
              # EventSource Publishing
              params = { payload: { index: index, family_id: family_id.to_s, renewal_year: renewal_year }, event_name: 'application_renewal_request_created' }

              Try do
                ::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new.call(params)
              end.bind do |result|
                if result.success?
                  logger.info "Successfully Published for event application_renewal_request_created, with params: #{params}"
                else
                  logger.info "Failed to publish for event application_renewal_request_created, with params: #{params}, failure: #{result.failure}"
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