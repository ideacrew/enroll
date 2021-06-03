# frozen_string_literal: true

module FinancialAssistance::Api::V1
    class ApplicationsController < FinancialAssistance::ApplicationController
      before_action :set_current_person

      include ::UIHelpers::WorkflowController
      include Acapi::Notifiers
      require 'securerandom'

      before_action :check_eligibility, only: [:create, :get_help_paying_coverage_response, :copy]
      before_action :init_cfl_service, only: [:review_and_submit, :raw_application]

      layout "financial_assistance_nav", only: %i[edit step review_and_submit eligibility_response_error application_publish_error]

      def index
        @applications = ::FinancialAssistance::Application.where(family_id: get_current_person.financial_assistance_identifier)

        render json: @applications
      end
    end
  end