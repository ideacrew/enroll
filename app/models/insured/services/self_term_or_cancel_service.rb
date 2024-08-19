# frozen_string_literal: true

module Insured
  module Services
    class SelfTermOrCancelService
      include ActionView::Helpers::NumberHelper

      def initialize(attrs)
        @enrollment_id  = attrs[:enrollment_id]
        @family_id      = attrs[:family_id]
        @term_date      = attrs[:term_date].present? ? Date.strptime(attrs[:term_date], '%m/%d/%Y') : TimeKeeper.date_of_record
        @term_or_cancel = attrs[:term_or_cancel]
        @elected_aptc_pct = attrs[:elected_aptc_pct]
        @selected_aptc = attrs[:aptc_applied_total]
        @cancellation_reason = attrs[:cancellation_reason]
        @factory_class = ::Insured::Factories::SelfServiceFactory
        @exclude_enrollments_list = attrs[:exclude_enrollments_list]
      end

      def find
        form_params = @factory_class.find(@enrollment_id, @family_id)
        attributes_to_form_params(form_params)
      end

      def validate_rating_address
        @factory_class.new({family_id: @family_id}).validate_rating_address
      end

      def term_or_cancel
        @factory_class.term_or_cancel(@enrollment_id, @term_date, @term_or_cancel, @cancellation_reason)
      end

      def update_aptc
        @factory_class.update_aptc(@enrollment_id, @selected_aptc.to_f, exclude_enrollments_list: @exclude_enrollments_list, elected_aptc_pct: @elected_aptc_pct.to_f)
      end

      def attributes_to_form_params(attrs)
        {
          :enrollment => ::Insured::Serializers::EnrollmentSerializer.new(attrs[:enrollment]).to_hash,
          :market_kind => attrs[:qle].present? ? attrs[:qle].market_kind : nil,
          :product => ::Insured::Services::ProductService.new(attrs[:enrollment].product).find,
          :family => ::Insured::Serializers::FamilySerializer.new(attrs[:family]).to_hash,
          :is_aptc_eligible => attrs[:is_aptc_eligible],
          new_effective_on: attrs[:new_effective_on],
          available_aptc: attrs[:available_aptc],
          elected_aptc_pct: attrs[:elected_aptc_pct],
          default_tax_credit_value: attrs[:default_tax_credit_value],
          max_tax_credit: attrs[:max_tax_credit],
          new_enrollment_premium: attrs[:new_enrollment_premium],
          cancellation_reason: attrs[:cancellation_reason]
        }
      end
    end
  end
end
