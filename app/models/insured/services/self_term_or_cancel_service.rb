# frozen_string_literal: true

module Insured
  module Services
    class SelfTermOrCancelService
      include ActionView::Helpers::NumberHelper

      def initialize(attrs)
        @enrollment_id = attrs[:enrollment_id]
        @family_id     = attrs[:family_id]
        @term_date     = attrs[:term_date].present? ? Date.strptime(attrs[:term_date], '%m/%d/%Y') : TimeKeeper.date_of_record
        @enrollment    = ::Insured::Factories::SelfServiceFactory.enrollment(@enrollment_id)
      end

      def find
        @family         = ::Insured::Factories::SelfServiceFactory.family(@family_id)
        sep             = ::Insured::Factories::SelfServiceFactory.sep(@family.latest_active_sep.id)
        qle             = ::Insured::Factories::SelfServiceFactory.qle_kind(sep.qualifying_life_event_kind_id)
        attributes_to_form_params({enrollment: @enrollment, family: @family, qle: qle})
      end

      def term_or_cancel(should_term_or_cancel)
        @enrollment.term_or_cancel_enrollment(@enrollment, @term_date)
        if should_term_or_cancel == 'cancel'
          transmit_flag = true
          notify(
            "acapi.info.events.hbx_enrollment.terminated",
            {
              :reply_to => "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler",
              "hbx_enrollment_id" => @enrollment_id,
              "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
              "is_trading_partner_publishable" => transmit_flag
            }
          )
        end
      end

      def current_premium
        if @enrollment.is_shop?
          @enrollment.total_employee_cost
        elsif @enrollment.kind == 'coverall'
          @enrollment.total_premium
        else
          @enrollment.total_premium > @enrollment.applied_aptc_amount.to_f ? @enrollment.total_premium - @enrollment.applied_aptc_amount.to_f : 0
        end
      end

      def is_aptc_eligible?
        allowed_metal_levels = ["platinum", "silver", "gold", "bronze"]
        product = @enrollment.product
        tax_household = @family.active_household.latest_active_tax_household if @family.active_household.latest_active_tax_household.present?
        aptc_members = tax_household.aptc_members if tax_household.present?
        return true if allowed_metal_levels.include?(product.metal_level_kind.to_s) && @enrollment.household.tax_households.present? && aptc_members.present?
      end

      def attributes_to_form_params(attrs)
        {
          :covered_members => attrs[:enrollment].covered_members_first_names,
          :is_under_ivl_oe => attrs[:family].is_under_ivl_open_enrollment?,
          :should_term_or_cancel => attrs[:enrollment].should_term_or_cancel_ivl,
          :enrollment => ::Insured::Serializers::EnrollmentSerializer.new(attrs[:enrollment]).to_hash,
          :market_kind => attrs[:qle].market_kind,
          :product => ::Insured::Services::ProductService.new(attrs[:enrollment].product).find,
          :qle_kind_id => attrs[:family].latest_active_sep.qualifying_life_event_kind_id,
          :sep_id => attrs[:family].latest_active_sep.id,
          :current_premium => number_to_currency(current_premium, precision: 2),
          :is_aptc_eligible => is_aptc_eligible?
        }
      end
    end
  end
end
