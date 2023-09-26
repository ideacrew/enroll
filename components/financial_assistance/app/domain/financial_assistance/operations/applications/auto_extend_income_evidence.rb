# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This operation processes the auto extend income evidence due date feature
      class AutoExtendIncomeEvidence
        include Dry::Monads[:result, :do]

        # @param [Hash] opts The options to update an income evidence due on date
        # @option opts [Date] :current_due_on (optional)
        # @option opts [String] :modified_by (optional)
        # @option opts [Integer] :extend_by (optional)
        # @return [Dry::Monads::Result]
        def call(params)
          validated_params = yield validate_input_params(params)
          update_evidences(validated_params)
        end

        private

        def validate_input_params(params)
          params[:current_due_on] = params[:current_due_on] || TimeKeeper.date_of_record
          params[:extend_by] = params[:extend_by] || FinancialAssistanceRegistry[:auto_update_income_evidence_due_on].settings(:days).item
          params[:modified_by] = params[:modified_by] || "system"
          return Failure("Invalid param for key current_due_on, must be a Date") unless params[:current_due_on].is_a?(Date)
          return Failure("Invalid param for key extend_by, must be an Integer") unless params[:extend_by].is_a?(Integer)
          return Failure("Invalid param for key modified_by, must be a String") unless params[:modified_by].is_a?(String)
          Success(params)
        end

        def update_evidences(params)
          applications = FinancialAssistance::Application.determined.where(:"applicants.income_evidence.due_on" => params[:current_due_on], :"applicants.income_evidence.aasm_state".in => ['rejected', 'outstanding'])
          updated_applicants = []
          applications.each do |application|
            application.applicants.each do |applicant|
              next unless applicant.income_evidence&.can_be_extended?(params[:current_due_on])
              updated_applicants << applicant.person_hbx_id
              applicant.income_evidence.auto_extend_due_on(params[:extend_by].days, params[:modified_by])
            end
          end

          Success(updated_applicants)
        rescue StandardError => e
          Failure("Failed to auto extend income evidence due on because of #{e.message}")
        end
      end
    end
  end
end
