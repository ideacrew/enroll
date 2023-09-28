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
          families = yield fetch_families
          update_evidences(validated_params, families)
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

        def fetch_families
          eligibile_family_ids = Family.where(:eligibility_determination => { :$exists => true }, :"eligibility_determination.outstanding_verification_status" => { :$eq => "outstanding" })&.distinct(:id)
          return Success(eligibile_family_ids) if eligibile_family_ids.present?
          Failure("No families found with outstanding verification status")
        end

        def update_evidences(params, families)
          updated_applicants = []
          families.each do |family_id|
            application = fetch_eligible_application(family_id, params[:current_due_on])
            next unless application
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

        def fetch_eligible_application(family_id, due_on)
          applications = FinancialAssistance::Application.where(
            family_id: family_id,
            aasm_state: 'determined'
          )
          return nil unless applications.any?
          application = applications.max_by(&:created_at)
          return nil unless application.applicants.detect { |applicant| applicant.income_evidence&.can_be_extended?(due_on) }
          application
        end
      end
    end
  end
end
