# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'csv'

module Operations
  module Eligibilities
    # update verification due on dates
    class UpdateVerificationDueDates
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to update evidence due on dates
      # @option opts [Family] :family required
      # @option opts [Integer] :assistance_year required
      # @option opts [Date] :due_on required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        family = yield update_aca_individual_eligibility_due_dates(values)
        _application = yield update_aptc_csr_eligibility_due_dates(values)

        Success(family)
      end

      private

      def validate(params)
        return Failure('family missing') unless params[:famiy] || params[:family].is_a?(::Family)

        return Failure('assistance_year missing') unless params[:assistance_year]
        return Failure('due_on missing') unless params[:due_on]

        Success(params)
      end

      def update_aca_individual_eligibility_due_dates(values)
        results =
          values[:family].family_members.active.collect do |family_member|
            update_person_eligibilities(family_member.person, values[:due_on], hard_update: values[:hard_update])
          end

        if results.all?(&:success?)
          Success(values[:family])
        else
          errors =
            results.collect do |result|
              result.failure.errors if result.failure?
            end.compact

          Failure(errors)
        end
      end

      def update_person_eligibilities(person, due_on, hard_update: true)
        outstanding_statuses = %w[outstanding review rejected]

        type_names = ["Social Security Number", "American Indian Status", "Citizenship", "Immigration status", ::VerificationType::LOCATION_RESIDENCY]
        type_names.each do |type_name|
          verification_types = person.verification_types.active.by_name(type_name)
          verification_types.each do |verification_type|
            verification_type.due_date = due_on if verification_type && outstanding_statuses.include?(verification_type.validation_status) && (hard_update || verification_type.due_date.nil?)
          end
        end

        person.save ? Success(person) : Failure(person.errors)
      end

      def update_aptc_csr_eligibility_due_dates(values)
        application =
          ::FinancialAssistance::Application
          .where(family_id: values[:family].id)
          .by_year(values[:assistance_year])
          .determined
          .last

        if application
          results =
            application.active_applicants.collect do |applicant|
              update_applicant_evidence_due_dates(applicant, values[:due_on], hard_update: values[:hard_update])
            end

          if results.all?(&:success?)
            Success(values[:family])
          else
            errors =
              results.collect do |result|
                result.failure.errors if result.failure?
              end.compact
            Failure(errors)
          end
        else
          Success(true)
        end
      end

      def update_applicant_evidence_due_dates(applicant, due_on, hard_update: true)
        evidences = %w[
          income_evidence
          esi_evidence
          non_esi_evidence
          local_mec_evidence
        ]

        evidences.each do |evidence_name|
          evidence_record = applicant.send(evidence_name)
          verify_and_update_evidence_due_on(evidence_record, due_on) if evidence_record && (hard_update || evidence_record.due_on.nil?)
        end

        applicant.save ? Success(applicant) : Failure(applicant.errors)
      end

      def verify_and_update_evidence_due_on(evidence_record, due_on)
        if ::Eligibilities::Evidence::OUTSTANDING.include?(
          evidence_record.aasm_state.to_sym
        )
          evidence_record.change_due_on!(due_on)
        end
      end
    end
  end
end
