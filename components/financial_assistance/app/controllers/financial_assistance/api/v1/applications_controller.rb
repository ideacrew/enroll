# frozen_string_literal: true

module FinancialAssistance::API::V1
  class ApplicationsController < FinancialAssistance::ApplicationController
    before_action :set_current_person

    include ::UIHelpers::WorkflowController
    include Acapi::Notifiers
    require 'securerandom'

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

    private

    def application_valid_params
      params.require(:application).permit(
        :is_ssn_applied,
        :non_ssn_apply_reason,
        :is_pregnant,
        :pregnancy_due_on,
        :children_expected_count,
        :is_post_partum_period,
        :pregnancy_end_on,
        :is_former_foster_care,
        :foster_care_us_state,
        :age_left_foster_care,
        :is_student,
        :student_kind,
        :student_status_end_on,
        :student_school_kind,
        :is_self_attested_blind,
        :has_daily_living_help,
        :need_help_paying_bills,
        :addresses_attributes => [
          :kind,
          :address_1,
          :address_2,
          :city,
          :state,
          :zip
        ],
        phones_attributes: [
          :kind,
          :number,
          :area_code
        ]
      )
    end
  end
end