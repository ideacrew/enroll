# frozen_string_literal: true

module Eligibilities
  module Visitors
    # Use Visitor Development Pattern to access models and determine Non-ESI
    # eligibility status for a Family Financial Assistance Application's Applicants
    class HealthProductEnrollmentStatusVisitor < Visitor
      attr_accessor :evidence, :subject, :evidence_item, :effective_date

      def call
        enrollment = hbx_enrollment_instance_for(subject, effective_date)
        unless enrollment
          @evidence = Hash[evidence_item[:key], {}]
          return
        end
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
          .by_health
          .enrolled_and_renewing
          .last
      end

      def evidence_state_for(enrollment_member)
        evidence_state_attributes = {
          status: 'determined',
          meta: {
            coverage_start_on: enrollment_member.coverage_start_on,
            csr_variant_id: enrollment_member.parent.product.csr_variant_id,
            enrollment_status: enrollment_member.parent.aasm_state
          },
          is_statisfied: true,
          verification_outstanding: false,
          visited_at: DateTime.now,
          due_on: nil
        }

        Hash[evidence_item[:key].to_sym, evidence_state_attributes]
      end
    end
  end
end