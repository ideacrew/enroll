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
        "Kaiser" => "https://kp.org/paypremium",
        "Community Health Options" => "https://healthoptions.org",
        "Harvard Pilgrim Health Care" => "https://www.harvardpilgrim.org/public/home",
        "Anthem Blue Cross and Blue Shield" => "https://www.anthem.com/contact-us/maine",
        "Northeast Delta Dental" => "https://www.nedelta.com/Home",
        "Taro Health Plan of Maine, Inc." => "https://uatthi.onlineinsight.com/ebpp/eapp/paynow"
      }.freeze

      # rubocop:disable Metrics/CyclomaticComplexity
      def show_pay_now?(source, hbx_enrollment)
        carrier_name = hbx_enrollment&.product&.issuer_profile&.legal_name
        @issuer_key = fetch_issuer_name(carrier_name)
        return false unless carrier_paynow_enabled(@issuer_key) && can_pay_now?(hbx_enrollment)
        rr_feature_enabled = EnrollRegistry.feature_enabled?("#{@issuer_key}_pay_now".to_sym)
        return false unless rr_feature_enabled == true
        return !pay_now_button_timed_out?(hbx_enrollment) if source == "Plan Shopping"
        return past_effective_on?(hbx_enrollment) if source == "Enrollment Tile"
        false
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def issuer_key(enrollment)
        carrier_key = enrollment&.product&.issuer_profile&.legal_name
        fetch_issuer_name(carrier_key)
      end

      def can_pay_now?(hbx_enrollment)
        individual?(hbx_enrollment) && (has_break_in_coverage_enrollments?(hbx_enrollment) || !has_any_previous_enrollments?(hbx_enrollment))
      end

      def carrier_url(legal_name)
        LINK_URL[legal_name]
      end

      def carrier_link(product)
        legal_name = product.issuer_profile.legal_name
        (link_to l10n("plans.issuer.pay_now.first_payment"), carrier_url(legal_name), class: "btn-link btn-block dropdown-item", style: 'padding: 6px 12px; margin: 4px 0;', target: '_blank').html_safe
      end

      def individual?(hbx_enrollment)
        hbx_enrollment.kind.in?(['individual', 'coverall'])
      end

      def has_any_previous_enrollments?(hbx_enrollment)
        all_carrier_enrollments = hbx_enrollment.family.hbx_enrollments.where(:aasm_state.nin => ["inactive", "shopping", "coverage_canceled"]).select do |enr|
          next if enr.product.blank? || enr.subscriber.blank? || enr.is_shop?
          fetch_issuer_name(enr.product.issuer_profile.legal_name) == @issuer_key && enr.effective_on.year == hbx_enrollment.effective_on.year && enr.subscriber.applicant_id == hbx_enrollment.subscriber.applicant_id
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
        issuer = fetch_issuer_name(issuer)
        issuer.present? && EnrollRegistry.key?("feature_index.#{issuer}_pay_now") && EnrollRegistry["#{issuer}_pay_now".to_sym].feature.is_enabled
      end

      def is_kaiser_translation_key?(carrier_key)
        carrier_key == 'kaiser' ? 'issuer' : 'other'
      end

      def carrier_long_name(issuer)
        issuer_key = fetch_issuer_name(issuer)
        carrier_paynow_enabled(issuer) ? EnrollRegistry["#{issuer_key}_pay_now".to_sym].settings[2].item : issuer
      end

      def pay_now_url(issuer_name)
        if carrier_paynow_enabled(issuer_name)
          issuer_name = fetch_issuer_name(issuer_name)
          SamlInformation.send("#{issuer_name}_pay_now_url")
        else
          "https://"
        end
      end

      def pay_now_relay_state(issuer_name)
        if carrier_paynow_enabled(issuer_name)
          issuer_name = fetch_issuer_name(issuer_name)
          SamlInformation.send("#{issuer_name}_pay_now_relay_state")
        else
          "https://"
        end
      end

      def enable_pay_now(hbx_enrollment)
        issuer = issuer_key(hbx_enrollment)
        return false unless individual?(hbx_enrollment) && EnrollRegistry.key?("feature_index.#{issuer}_pay_now")
        rr_feature = EnrollRegistry["#{@issuer_key}_pay_now".to_sym]
        return false unless rr_feature&.enabled?
        rr_feature.setting(:enrollment_tile)&.item
      end

      def fetch_issuer_name(issuer_name)
        carrier_legal_name = issuer_name&.downcase
        carrier_legal_name.downcase.gsub(' ', '_').gsub(/[,.]/, '')
      end
    end
  end
end
