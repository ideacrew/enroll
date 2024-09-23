# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # Query applications and associated data for a specified person.
      #
      # Also includes caching and performance improvements to reduce query
      # times.
      class QueryFilteredApplications
        include Dry::Monads[:do, :result]

        def call(params)
          validated_params = yield validate_params(params)

          query_filtered_records(validated_params)
        end

        def query_filtered_records(params)
          family_id = params[:family_id]
          filter_year = params[:filter_year]
          @applications = FinancialAssistance::Application.where("family_id" => family_id)
          @filtered_applications = filter_year.present? && !filter_year.nil? ? @applications.where(:assistance_year => filter_year) : @applications
          @filtered_applications = @filtered_applications.desc(:created_at).without(:relationships,:applicants,:workflow_state_transitions)

          determined_apps = @filtered_applications.where(:aasm_state => "determined")
          most_recent_year = determined_apps.pluck(:assistance_year).max
          @recent_determined_hbx_id = determined_apps.where(:assistance_year => most_recent_year).desc(:submitted_at).pluck(:hbx_id).first
          Success(
            {
              applications: @applications,
              filtered_applications: @filtered_applications,
              recent_determined_hbx_id: @recent_determined_hbx_id
            }
          )
        end

        def validate_params(params)
          validation_result = ::FinancialAssistance::Validators::FilteredApplicationIndexRequestContract.new.call(params)

          validation_result.success? ? Success(validation_result.to_h) : Failure(validation_result.errors)
        end
      end
    end
  end
end