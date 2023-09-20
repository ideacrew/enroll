# frozen_string_literal: true

module Enrollments
  module IndividualMarket
    # Helps encapsulate the complexity of the interaction between an
    # HbxEnrollment for which coverage was just selected and another
    # enrollment that may experience a change because of that selection.
    #
    # Note that only enrollments in the same plan year should be compared.
    class ProductSelectionInteraction

      attr_reader :selected_enrollment, :affected_enrollment

      def initialize(s_enrollment, a_enrollment)
        @selected_enrollment = s_enrollment
        @affected_enrollment = a_enrollment
      end

      def affected_effective_on
        @affected_enrollment.effective_on
      end

      def affected_terminated_on
        @affected_enrollment.terminated_on
      end

      # Determines if it is even possible for the enrollments to interact
      # as a result of a purchase.  Used early in the process to eliminate
      # enrollments that should not be affected.
      def can_interact?
        return false if HbxEnrollment::CANCELED_STATUSES.include?(@affected_enrollment.aasm_state)
        return false unless @selected_enrollment.coverage_kind == @affected_enrollment.coverage_kind
        return false unless @selected_enrollment.subscriber.applicant_id == @affected_enrollment.subscriber.applicant_id

        return true if @affected_enrollment.effective_on >= @selected_enrollment.effective_on
        return true if @affected_enrollment.effective_on <= @selected_enrollment.effective_on && @affected_enrollment.terminated_on.blank?
        (@affected_enrollment.effective_on <= @selected_enrollment.effective_on) && (@affected_enrollment.terminated_on >= @selected_enrollment.effective_on)
      end

      # Is the affected enrollment continous, coverage wise, with another,
      # specified enrollment?
      def continous_with?(next_enrollment)
        return false unless @affected_enrollment.product_id == next_enrollment.affected_enrollment.product_id
        return false if @affected_enrollment.terminated_on.blank?
        @affected_enrollment.terminated_on == (next_enrollment.affected_effective_on - 1.day)
      end
    end
  end
end