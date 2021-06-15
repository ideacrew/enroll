# frozen_string_literal: true

module FinancialAssistance::API::V1
    class ApplicationsController < FinancialAssistance::ApplicationController
      before_action :set_current_person

      include ::UIHelpers::WorkflowController
      include Acapi::Notifiers
      require 'securerandom'

      before_action :check_eligibility, only: [:create, :get_help_paying_coverage_response, :copy]
      before_action :init_cfl_service, only: [:review_and_submit, :raw_application]

      def index
        @applications = ::FinancialAssistance::Application.where(family_id: get_current_person.financial_assistance_identifier)

        render json: @applications
      end

      def create
        puts 'testingggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg'
        @application = FinancialAssistance::Application.where(
          aasm_state: "draft",
          family_id: get_current_person.financial_assistance_identifier
        ).new(params[:application])

        if @application.save
          render json: @application
        else
          render json: { errors: @application.errors.full_messages }, status: :bad_request
        end
      end
    end
  end