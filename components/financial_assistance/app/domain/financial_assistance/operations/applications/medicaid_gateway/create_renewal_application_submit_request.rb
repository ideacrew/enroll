# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # This class will query all renewal draft applications by renewal year and trigger renewal events
        class GenerateApplicationSubmitEvents
          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          def call(params)
            applications = yield find_applications(params[:renewal_year])
            applications = yield generate_requests(params[:renewal_year], applications)

            Success(applications)
          end

          private

          def find_applications(renewal_year)
            applications = FinancialAssistance::Application.renewal_draft.where(assistance_year: renewal_year)

            Success(applications)
          end

          # rubocop:disable Style/MultilineBlockChain
          def generate_requests(renewal_year, applications)
            @logger.info "Total number of renewal_draft applications with assistance_year: #{renewal_year.pred} are #{applications.count}"

            applications.each_with_index do |application, index|
              params = { payload: { index: index, application_hbx_id: application.hbx_id.to_s }, event_name: 'submit_renewal_draft' }
              Try do
                ::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new.call(params)
              end.bind do |result|
                if result.success?
                  @logger.info "Successfully Published for event submit_renewal_draft, with params: #{params}"
                else
                  @logger.info "Failed to publish for event submit_renewal_draft, with params: #{params}, failure: #{result.failure}"
                end
              end
            end
            # rubocop:enable Style/MultilineBlockChain

            Success(applications)
          end
        end
      end
    end
  end
end