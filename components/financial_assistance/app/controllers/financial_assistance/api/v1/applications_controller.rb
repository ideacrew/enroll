# frozen_string_literal: true

module FinancialAssistance::Api::V1
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
      @application = FinancialAssistance::Application.where(
        aasm_state: "draft",
        family_id: get_current_person.financial_assistance_identifier
      ).new(application_valid_params)

      if @application.save
        render json: @application
      else
        render json: { errors: @application.errors.full_messages }, status: :bad_request
      end
    end

    def update
      @application = FinancialAssistance::Application.find_by(family_id: get_current_person.financial_assistance_identifier)
      if @application.update(application_valid_params)
        render json: @application
      else
        render json: { errors: @application.errors.full_messages }, status: :bad_request
      end
    end

    def show
      @application = FinancialAssistance::Application.find_by(:family_id)
      render json: @application
    end

    def destroy
      @application = FinancialAssistance::Application.find_by(family_id: get_current_person.financial_assistance_identifier)
      if @application.destroy
        head :no_content
      else
        render json: { errors: @application.errors.full_messages }, status: :bad_request
      end
    end

    private

    def application_valid_params
      params.require(:application).permit(
        :applicants_attributes => [
          :id,
          :tax_filer_kind,
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
          ],
          emails_attributes: [
                    :kind,
                    :address,
          ],
          deductions_attributes: [
                    :amount,
                    :frequency_kind,
                    :start_on,
                    :end_on,
                    :kind
          ],
          deductions_attributes: [
                    :amount,
                    :frequency_kind,
                    :start_on,
                    :end_on,
                    :kind
          ],
          incomes_attributes: [
                    :kind,
                    :employer_name,
                    :amount,
                    :frequency_kind,
                    :start_on,
                    :end_on,
                    :employer_address => [
                      # :kind,
                      # :address_1,
                      # :address_2,
                      # :city,
                      # :state,
                      # :zip
                    ],
                    :employer_phone => [
                      # :kind,
                      # :full_phone_number
                    ]
          ],
          benefits_attributes: [
                    :kind,
                    :start_on,
                    :end_on,
                    :insurance_kind,
                    :esi_covered,
                    :employer_name,
                    :employee_cost,
                    :employee_id,
                    :employee_cost_frequency
          ]
        ]
      )
    end
  end
end