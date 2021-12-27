# frozen_string_literal: true

module Eligibilities
  module Visitors
    # Use Visitor Development Pattern to access models and determine Non-ESI
    # eligibility status for a Family Financial Assistance Application's Applicants
    class DentalProductEnrollmentStatusVisitor < Visitor
      attr_accessor :evidence, :subject, :evidence_item, :effective_date

      def call
        enrollment = hbx_enrollment_instance_for(subject, effective_date)

        enrollment.accept(self)
      end

      def visit(enrollment_member)
        return unless enrollment_member.applicant_id == subject.id

        @evidence = evidence_state_for(enrollment_member)
      end

      private

      def hbx_enrollment_instance_for(subject, effective_date)
        HbxEnrollment
          .where(
            :family_id => subject.family.id,
            :effective_date.gte => effective_date.beginning_of_year,
            :effective_date.lte => effective_date
          )
          .by_dental
          .enrolled_and_renewing
          .last
      end

      def evidence_state_for(enrollment_member)
        evidence_state_attributes = {
          status: enrollment_member.parent.aasm_state,
          meta: {
            coverage_start_on: enrollment_member.coverage_start_on
          },
          is_statisfied: true,
          verification_outstanding: false
        }

        Hash[evidence_item[:key].to_sym, evidence_state_attributes]
      end
    end
  end
end
