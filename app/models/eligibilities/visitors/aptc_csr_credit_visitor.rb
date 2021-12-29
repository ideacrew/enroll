# frozen_string_literal: true

module Eligibilities
  module Visitors
    # Use Visitor Development Pattern to access models and determine Non-ESI
    # eligibility status for a Family Financial Assistance Application's Applicants
    class AptcCsrCreditVisitor < Visitor
      attr_accessor :evidence, :subject, :evidence_item, :effective_date

      def call
        application = application_instance_for(subject, effective_date)
        unless application
          @evidence = Hash[evidence_item[:key], {}]
          return
        end

        application.accept(self)
      end

      def visit(applicant)
        return unless applicant.family_member_id == subject.id

        current_record = applicant.send(evidence_item[:key])
        unless current_record
          @evidence = Hash[evidence_item[:key], {}]
          return
        end

        evidence_record = evidence_record_for(current_record, effective_date)
        @evidence = evidence_state_for(evidence_record)
      end

      private

      def application_instance_for(subject, effective_date)
        year_begin = effective_date.beginning_of_year

        ::FinancialAssistance::Application.where(
          :family_id => subject.family.id,
          :aasm_state => 'determined',
          :effective_date.gte => DateTime.new(year_begin.year, year_begin.month, year_begin.day),
          :effective_date.lte => DateTime.new(effective_date.year, effective_date.month, effective_date.day)
        ).last
      end

      def evidence_record_for(current_record, effective_date)
        evidence_history =
          current_record
          .verification_histories
          .where(:created_at.lte => effective_date)
          .last

        evidence_history || current_record
      end

      def evidence_state_for(evidence_record)
        ids = {
          'evidence_gid' => evidence_record.to_global_id.uri,
          'visited_at' => DateTime.now,
          'status' => evidence_record.aasm_state
        }

        evidence_state_attributes =
          evidence_record
          .attributes
          .slice('is_satisfied', 'verification_outstanding', 'due_on')
          .merge(ids)

        due_on_value = evidence_state_attributes['due_on']
        evidence_state_attributes['due_on'] = due_on_value.to_date if due_on_value.is_a?(DateTime) || due_on_value.is_a?(Time)
        evidence_state_attributes.delete('due_on') if evidence_state_attributes['due_on'].blank?

        Hash[evidence_item[:key].to_sym, evidence_state_attributes.symbolize_keys]
      end
    end
  end
end
