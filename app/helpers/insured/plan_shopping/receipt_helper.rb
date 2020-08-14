module Insured
  module PlanShopping
    module ReceiptHelper
      def show_pay_now?
        return false unless EnrollRegistry[:pay_now_functionality].feature.is_enabled
        (carrier_with_payment_option? && individual? && (!has_any_previous_kaiser_enrollments? || has_break_in_coverage_enrollments?)) && pay_now_button_timed_out?
      end

      def carrier_with_payment_option?
        @enrollment.product.issuer_profile.legal_name == EnrollRegistry[:pay_now_functionality].setting(:carriers).item
      end

      def individual?
        @enrollment.kind.in?(['individual', 'coverall'])
      end

      def has_any_previous_kaiser_enrollments?
        carrier = EnrollRegistry[:pay_now_functionality].setting(:carriers).item
        all_kaiser_enrollments = @enrollment.family.hbx_enrollments.to_a.select { |enr| !enr.product_id.nil? && enr.product.issuer_profile.legal_name == carrier && enr.effective_on.year == @enrollment.effective_on.year }
        enrollments = all_kaiser_enrollments - @enrollment.to_a
        enrollments.present? ? true : false
      end

      def pay_now_button_timed_out?
        @enrollment.submitted_at + 15.minutes > TimeKeeper.datetime_of_record
      end

      def has_break_in_coverage_enrollments?
        enrollments = @enrollment.family.enrollments.current_year.where(aasm_state: "coverage_terminated")
        carrier = EnrollRegistry[:pay_now_functionality].setting(:carriers).item
        enrollments.any? { |enr| enr.product.issuer_profile.legal_name == carrier && enr.terminated_on.year == @enrollment.effective_on.year && (@enrollment.effective_on - enr.terminated_on) > 1 }
      end
    end
  end
end
