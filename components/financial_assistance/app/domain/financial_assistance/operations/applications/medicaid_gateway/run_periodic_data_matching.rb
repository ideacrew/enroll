# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        # Operation to fetch needed families to call Local Medicaid ME service
        # to fetch and update application determination eligibility
        class RunPeriodicDataMatching
          include Dry::Monads[:result, :do]
          include EventSource::Command
          include EventSource::Logging

          def call(params)
            values = yield validate(params)
            applications = fetch_determined_applications(values)
            publish(params, applications)

            Success('Successfully ran Periodic Data matching')
          end

          private

          def validate(params)
            errors = []
            errors << 'assistance_year ref missing' unless params[:assistance_year]

            errors.empty? ? Success(params) : Failure(errors)
          end

          def fetch_determined_applications(params)
            applications = []
            family_ids = FinancialAssistance::Application.where(:aasm_state => "determined",
                                                                :assistance_year => params[:assistance_year],
                                                                :"applicants.is_ia_eligible" => true).distinct(:family_id)
            Family.where(:_id.in => family_ids).all.each do |family|
              determined_application = fetch_application(family, params[:assistance_year])
              next unless determined_application.present? && is_aptc_or_csr_eligible?(determined_application)
              applications << determined_application
            end
            applications
          end

          def is_aptc_or_csr_eligible?(application)
            application.aptc_applicants.present?
          end

          def publish(params, applications)
            applications.each do |application|
              FinancialAssistance::Operations::Applications::RequestMecChecks.new.call(application_id: application._id)
            end
          end

        end
      end
    end
  end
end
