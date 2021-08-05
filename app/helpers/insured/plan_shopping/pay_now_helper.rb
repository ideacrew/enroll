#frozen_string_literal: true

module Insured
  module PlanShopping
    #helper related to paynow feature
    module PayNowHelper
      LINK_URL = {
        "BEST Life" => 'https://www.bestlife.com/exchange/payment_option.html',
        "CareFirst" => "https://member.carefirst.com/members/home.page",
        "Delta Dental" => "https://www1.deltadentalins.com/login.html",
        "Dominion National" => "https://www.dominionmembers.com/",
        "Kaiser" => "https://kp.org/paypremium"
      }.freeze

      # rubocop:disable Metrics/CyclomaticComplexity
      def show_pay_now?(source, hbx_enrollment)
        @issuer_key = hbx_enrollment&.product&.issuer_profile&.legal_name&.downcase&.gsub(' ', '_')
        return false unless carrier_paynow_enabled(@issuer_key) && can_pay_now?(hbx_enrollment)
        rr_feature = EnrollRegistry["#{@issuer_key}_pay_now".to_sym]
        return !pay_now_button_timed_out?(hbx_enrollment) if source == "Plan Shopping" && rr_feature.setting(:plan_shopping).item
        return past_effective_on?(hbx_enrollment) if source == "Enrollment Tile" && rr_feature.setting(:enrollment_tile).item
        false
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def issuer_key(enrollment)
        enrollment&.product&.issuer_profile&.legal_name&.downcase&.gsub(' ', '_')
      end

      def can_pay_now?(hbx_enrollment)
        return true if individual?(hbx_enrollment) && (has_break_in_coverage_enrollments?(hbx_enrollment) || !has_any_previous_enrollments?(hbx_enrollment))
      end

      def carrier_url(legal_name)
        LINK_URL[legal_name]
      end

      def carrier_link(product)
        legal_name = product.issuer_profile.legal_name
        (link_to l10n("plans.kaiser.pay_now.first_payment"), carrier_url(legal_name), class: "btn-link btn-block dropdown-item", style: 'padding: 6px 12px; margin: 4px 0;', target: '_blank').html_safe
      end

      def individual?(hbx_enrollment)
        hbx_enrollment.kind.in?(['individual', 'coverall'])
      end

      def has_any_previous_enrollments?(hbx_enrollment)
        all_carrier_enrollments = hbx_enrollment.family.hbx_enrollments.where(:aasm_state.nin => ["inactive", "shopping", "coverage_canceled"]).select do |enr|
          next if enr.product.blank? || enr.subscriber.blank? || enr.is_shop?
          enr.product.issuer_profile.legal_name.downcase&.gsub(' ', '_') == @issuer_key && enr.effective_on.year == hbx_enrollment.effective_on.year && enr.subscriber.id == hbx_enrollment.subscriber.id
        end
        enrollments = all_carrier_enrollments - hbx_enrollment.to_a
        enrollments.present? ? true : false
      end

      def pay_now_button_timed_out?(hbx_enrollment)
        covered_time = hbx_enrollment.workflow_state_transitions.where(to_state: 'coverage_selected').first
        return true if covered_time.blank?
        covered_time.transition_at + 15.minutes <= Time.now
      end

      def past_effective_on?(hbx_enrollment)
        hbx_enrollment.effective_on > TimeKeeper.date_of_record
      end

      def has_break_in_coverage_enrollments?(hbx_enrollment)
        enrollments = hbx_enrollment.family.enrollments.current_year.where(aasm_state: "coverage_terminated")
        enrollments.any? { |enr| enr.terminated_on.year == hbx_enrollment.effective_on.year && (hbx_enrollment.effective_on - enr.terminated_on) > 1 }
      end

      def carrier_paynow_enabled(issuer)
        issuer = issuer.downcase&.gsub(' ', '_')
        issuer.present? && EnrollRegistry.key?("feature_index.#{issuer}_pay_now") && EnrollRegistry["#{issuer}_pay_now".to_sym].feature.is_enabled
      end

      def pay_now_url(issuer_name)
        if carrier_paynow_enabled(issuer_name)
          issuer_name = issuer_name.downcase&.gsub(' ', '_')
          SamlInformation.send("#{issuer_name}_pay_now_url")
        else
          "https://"
        end
      end

      def pay_now_relay_state(issuer_name)
        if carrier_paynow_enabled(issuer_name)
          issuer_name = issuer_name.downcase&.gsub(' ', '_')
          SamlInformation.send("#{issuer_name}_pay_now_relay_state")
        else
          "https://"
        end
      end
    end
  end
end
