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
        "Kaiser Permanente" => "https://kp.org/paypremium",
        "Community Health Options" => "https://healthoptions.org",
        "Harvard Pilgrim Health Care" => "https://www.harvardpilgrim.org/public/home",
        "Anthem Blue Cross and Blue Shield" => "https://www.anthem.com/contact-us/maine",
        "Northeast Delta Dental" => "https://www.nedelta.com/Home",
        "Taro Health" => EnrollRegistry['taro_health_pay_now'].setting(:taro_health_home_page_url).item
      }.freeze

      def show_pay_now?(source, hbx_enrollment)
        @carrier_key = fetch_carrier_key_from_legal_name(hbx_enrollment&.product&.issuer_profile&.legal_name)

        return unless carrier_paynow_enabled?(@carrier_key) && enrollment_can_pay_now?(hbx_enrollment)

        case source
        when "Plan Shopping"
          !pay_now_button_timed_out?(hbx_enrollment)
        when "Enrollment Tile"
          EnrollRegistry["#{@carrier_key}_pay_now".to_sym].setting(:enrollment_tile).item
        end
      end

      def show_generic_redirect?(hbx_enrollment)
        generic_redirect_enabled = EnrollRegistry.feature_enabled?(:generic_redirect)
        return unless generic_redirect_enabled

        @carrier_key = fetch_carrier_key_from_legal_name(hbx_enrollment&.product&.issuer_profile&.legal_name)
        strict_tile_check_enabled = EnrollRegistry[:generic_redirect].setting(:strict_tile_check).item
        enrollment_tile_enabled = EnrollRegistry["#{@carrier_key}_pay_now".to_sym].setting(:enrollment_tile).item

        strict_tile_check_enabled ? enrollment_tile_enabled : generic_redirect_enabled
      end

      def carrier_key_from_enrollment(enrollment)
        carrier_key = enrollment&.product&.issuer_profile&.legal_name
        fetch_carrier_key_from_legal_name(carrier_key)
      end

      def enrollment_can_pay_now?(hbx_enrollment)
        return if hbx_enrollment.aasm_state == "auto_renewing"
        has_break_in_coverage_enrollments?(hbx_enrollment) || !has_any_previous_enrollments?(hbx_enrollment)
      end

      def carrier_url(legal_name)
        LINK_URL[legal_name]
      end

      def carrier_link(product)
        legal_name = product.issuer_profile.legal_name
        link_to(l10n("plans.issuer.pay_now.make_first_payment"), carrier_url(legal_name), class: "btn-link btn-block dropdown-item", style: 'padding: 6px 12px; margin: 4px 0;', target: '_blank')
      end

      def enrollment_is_ivl_or_coverall?(hbx_enrollment)
        hbx_enrollment.kind.in?(['individual', 'coverall'])
      end

      def has_any_previous_enrollments?(hbx_enrollment)
        potential_previous_enrollments = hbx_enrollment.family.hbx_enrollments.where(:aasm_state.nin => ["inactive", "shopping", "coverage_canceled"]).select do |enr|
          next if enr.product.blank? || enr.subscriber.blank? || enr.is_shop?
          is_previous_enrollment?(hbx_enrollment, enr)
        end
        enrollments = potential_previous_enrollments - hbx_enrollment.to_a
        enrollments.present?
      end

      def is_previous_enrollment?(hbx_enrollment, enr)
        same_carrier = fetch_carrier_key_from_legal_name(enr.product.issuer_profile.legal_name) == @carrier_key
        same_year = enr.effective_on.year == hbx_enrollment.effective_on.year
        same_subscriber = enr.subscriber.applicant_id == hbx_enrollment.subscriber.applicant_id
        same_coverage_kind = enr.coverage_kind == hbx_enrollment.coverage_kind

        same_carrier && same_year && same_subscriber && same_coverage_kind
      end

      def pay_now_button_timed_out?(hbx_enrollment)
        covered_time = hbx_enrollment.workflow_state_transitions.where(:to_state.in => ['renewing_coverage_selected', 'coverage_selected']).first
        return true if covered_time.blank?
        covered_time.transition_at + 15.minutes <= Time.now
      end

      def before_effective_date?(hbx_enrollment)
        hbx_enrollment.effective_on > TimeKeeper.date_of_record
      end

      def has_break_in_coverage_enrollments?(hbx_enrollment)
        enrollments = hbx_enrollment.family.enrollments.current_year.where(aasm_state: "coverage_terminated")
        enrollments.any? { |enr| enr.terminated_on.year == hbx_enrollment.effective_on.year && (hbx_enrollment.effective_on - enr.terminated_on) > 1 }
      end

      def carrier_paynow_enabled?(carrier_name)
        carrier_key = fetch_carrier_key_from_legal_name(carrier_name)
        EnrollRegistry.key?("pay_now_feature.#{carrier_key}_pay_now") && EnrollRegistry.feature_enabled?("#{carrier_key}_pay_now".to_sym)
      end

      def is_kaiser_translation_key?(carrier_key)
        ['kaiser_permanente', 'kaiser'].include?(carrier_key) ? 'issuer' : 'other'
      end

      def carrier_long_name(carrier_name)
        carrier_key = fetch_carrier_key_from_legal_name(carrier_name)
        carrier_paynow_enabled?(carrier_name) ? EnrollRegistry["#{carrier_key}_pay_now"].setting(:carriers_long_name).item : carrier_name
      end

      def pay_now_url(carrier_name)
        if carrier_paynow_enabled?(carrier_name)
          carrier_key = fetch_carrier_key_from_legal_name(carrier_name)
          SamlInformation.send("#{carrier_key}_pay_now_url")
        else
          "https://"
        end
      end

      def pay_now_relay_state(carrier_name)
        if carrier_paynow_enabled?(carrier_name)
          carrier_key = fetch_carrier_key_from_legal_name(carrier_name)
          SamlInformation.send("#{carrier_key}_pay_now_relay_state")
        else
          "https://"
        end
      end

      def fetch_carrier_key_from_legal_name(carrier_key)
        carrier_legal_name = carrier_key&.downcase
        carrier_legal_name.downcase.gsub(' ', '_').gsub(/[,.]/, '')
      end
    end
  end
end
