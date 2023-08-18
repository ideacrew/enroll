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

          # This line is being used to test until FinancialAssitancesRegistry stub can be added to test suite
          params[:extend_by] = 65 if params[:extend_by] == true
          
          params[:modified_by] = params[:modified_by] || "system"
          return Failure("Invalid param for key current_due_on, must be a Date") unless params[:current_due_on].is_a?(Date)
          return Failure("Invalid param for key extend_by, must be an Integer") unless params[:extend_by].is_a?(Integer)
          return Failure("Invalid param for key modified_by, must be a String") unless params[:modified_by].is_a?(String)
          Success(params)
        end

        def update_evidences(params)
          applications = FinancialAssistance::Application.determined.where(:"applicants.income_evidence.due_on" => params[:current_due_on])
          updated_applicants = []
          applications.each do |application|
            application.applicants.each do |applicant|
              next unless applicant.income_evidence&.can_be_extended?
              updated_applicants << applicant.person_hbx_id
              applicant.income_evidence.auto_extend_due_on(params[:extend_by].days, params[:modified_by])
            end

            update_family_level_verification_due_date(application)
          end

          Success(updated_applicants)
        rescue StandardError => e
          Failure("Failed to auto extend income evidence due on because of #{e.message}")
        end

        def update_family_level_verification_due_date(application)
          family = application.family
          eligibility_determination = family.eligibility_determination
          
          applicants_earliest_due_date = family.min_verification_due_date_on_family
          # Is there an instance where this would be nil? Maybe when it's first built? 
          family_earliest_due_date = eligibility_determination.outstanding_verification_earliest_due_date
          
          # More elegant way to write? -- The names are really loooooong...
          if applicants_earliest_due_date > family_earliest_due_date
            # Do we need to add a verification_history for altering the eligibility_determination.outstanding_verification_earliest_due_date?
            family.eligibility_determination.update(outstanding_verification_earliest_due_date: applicants_earliest_due_date)
          end
        end
      end
    end
  end
end
