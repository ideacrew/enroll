# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This operation processes the auto extend income evidence due date feature
      class AutoExtendIncomeEvidence
        include Dry::Monads[:do, :result]

        # @param [Hash] opts The options to update an income evidence due on date
        # @option opts [Date] :current_due_on (optional)
        # @option opts [String] :modified_by (optional)
        # @option opts [Integer] :extend_by (optional)
        # @return [Dry::Monads::Result]
        def call(params)
          validated_params = yield validate_input_params(params)
          eligible_application_ids, eligibile_family_ids = yield fetch_applications(validated_params)
          eligible_families = yield fetch_families(validated_params, eligibile_family_ids)
          update_evidences(validated_params, eligible_families, eligible_application_ids)
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

        def fetch_applications(params)
          applications = FinancialAssistance::Application.determined.where(:"applicants.income_evidence.due_on" => params[:current_due_on], :"applicants.income_evidence.aasm_state".in => ['rejected', 'outstanding'])&.pluck(:_id, :family_id)
          return Failure("Failed to query applications with income evidence due on #{params[:current_due_on]}") unless applications.present?
          Success([applications.map(&:first), applications.map(&:last)])
        end

        def fetch_families(_params, eligibile_family_ids)
          eligibile_family_ids = Family.where(:_id.in => eligibile_family_ids, :eligibility_determination => { :$exists => true }, :"eligibility_determination.outstanding_verification_status" => { :$eq => "outstanding" })&.distinct(:id)
          return Failure("No families found with outstanding verification status") unless eligibile_family_ids.present?
          Success(eligibile_family_ids)
        end

        def update_evidences(params, families, eligible_applications)
          updated_applicants = []
          families.each do |family_id|
            application = fetch_eligible_application(family_id, eligible_applications)
            next unless application
            application.applicants.each do |applicant|
              next unless applicant.income_evidence&.can_be_auto_extended?(params[:current_due_on])
              updated_applicants << applicant.person_hbx_id
              applicant.income_evidence.auto_extend_due_on(params[:extend_by].days, params[:modified_by])
            end
          end
          Success(updated_applicants)
        rescue StandardError => e
          Failure("Failed to auto extend income evidence due on because of #{e.message}")
        end

        def fetch_eligible_application(family_id, eligible_applications)
          applications = FinancialAssistance::Application.where(
            family_id: family_id,
            aasm_state: 'determined'
          )
          return nil unless applications.any?
          application = applications.max_by(&:created_at)
          return nil unless application.id.in? eligible_applications
          application
        end
      end
    end
  end
end
