# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
        # This class will query all distinct app_ids with renwal draft applications and trigger eligibility_determination renewal events
        # Syntax: FinancialAssistance::Operations::Applications::TriggerEligibilityDetermination.new.call({renewal_year: 2023})
      class TriggerEligibilityDetermination
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        def call(params)
          app_ids = yield find_families(params[:renewal_year])
          app_ids = yield generate_renewal_events(params[:renewal_year], app_ids)

          Success(app_ids)
        end

        private

        def find_families(renewal_year)
          Success(::FinancialAssistance::Application.by_year(renewal_year).where(aasm_state: "renewal_draft").pluck(:id))
        end

        # rubocop:disable Style/MultilineBlockChain
        def generate_renewal_events(renewal_year, app_ids)
          logger = Logger.new("#{Rails.root}/log/trigger_eligibility_determination_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")

          logger.info 'Started publish_generate_draft_renewals process'
          logger.info "Total number of applications with assistance_year: #{renewal_year.pred} are #{app_ids.count}"
          app_ids.each_with_index do |app_id, index|
            # EventSource Publishing
            params = { payload: { index: index, application_id: app_id.to_s, renewal_year: renewal_year }, event_name: 'eligibility_determination_triggered' }

            Try do
              ::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new.call(params)
            end.bind do |result|
              if result.success?
                logger.info "Successfully Published for event eligibility_determination_triggered, with params: #{params}"
              else
                logger.info "Failed to publish for event eligibility_determination_triggered, with params: #{params}, failure: #{result.failure}"
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
