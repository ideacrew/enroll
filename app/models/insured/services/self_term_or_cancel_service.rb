# frozen_string_literal: true

module Insured
  module Services
    class SelfTermOrCancelService
      include ActionView::Helpers::NumberHelper

      def initialize(attrs)
        @enrollment_id = attrs[:enrollment_id]
        @family_id     = attrs[:family_id]
        @term_date     = attrs[:term_date].present? ? Date.strptime(attrs[:term_date], '%m/%d/%Y') : TimeKeeper.date_of_record
        @factory_class = ::Insured::Factories::SelfServiceFactory
        @family_class  = ::Insured::Factories::FamilyFactory
        @sep_class     = ::Insured::Factories::SepFactory
        @qle_class     = ::Insured::Factories::QualifyingLifeEventKindFactory
        @product_class = ::Insured::Factories::ProductFactory
      end

      def find
        enrollment = @factory_class.find(@enrollment_id)
        family     = @family_class.find(@family_id)
        sep        = @sep_class.find(family.latest_active_sep.id)
        qle        = @qle_class.find(sep.qualifying_life_event_kind_id)
        attributes_to_form_params({enrollment: enrollment, family: family, qle: qle})
      end

      def term_or_cancel(should_term_or_cancel)
        enrollment = @factory_class.find(@enrollment_id)
        enrollment.term_or_cancel_enrollment(enrollment, @term_date)
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
        enrollment = @factory_class.find(@enrollment_id)
        if enrollment.is_shop?
          enrollment.total_employee_cost
        elsif enrollment.kind == 'coverall'
          enrollment.total_premium
        else
          enrollment.total_premium > enrollment.applied_aptc_amount.to_f ? enrollment.total_premium - enrollment.applied_aptc_amount.to_f : 0
        end
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
          :current_premium => number_to_currency(current_premium, precision: 2)
        }
      end
    end
  end
end
