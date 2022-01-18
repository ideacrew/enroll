# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module Rrv
        # operation to manually trigger rrv events.
        # It will take families as input and find the determined application, add evidences and publish the group of applications
        class SubmitRrvSet
          include Dry::Monads[:result, :do]
          include EventSource::Command
          include EventSource::Logging

          def call(params)
            values = validate(params)
            families = find_families(values)

            submit(params, families)
            Success(result)
          end

          private

          def validate(params)
            errors = []
            errors << 'applications_per_event ref missing' unless params[:applications_per_event]
            errors << 'assistance_year ref missing' unless params[:assistance_year]

            errors.empty? ? Success(params) : Failure(errors)
          end

          def find_families(params)
            family_ids = FinancialAssistance::Application.where(aasm_state: "determined",
                                                                assistance_year: params[:assistance_year]).distinct(:family_id)
            Family.where(:_id.in => family_ids)
          end

          def submit(params, families)
            skip = params[:skip] || 0
            applications_per_event = params[:applications_per_event]

            while skip < families.count
              criteria = families.skip(skip).limit(applications_per_event)
              FinancialAssistance::Operations::Applications::Rrv::CreateRrvRequest.new.call({families: criteria, assistance_year: params[:assistance_year]})
              puts "Total number of reecords processeed #{skip + criteria.pluck(:id).length}"
              skip += applications_per_event

              break if params[:max_applications].present? && params[:max_applications] > skip
            end
          end
        end
      end
    end
  end
end
