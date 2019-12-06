# frozen_string_literal: true

module Insured
  module Forms
    class SelfTermOrCancelForm
      include ActiveModel::Validations
      include Virtus.model

      attribute :carrier_logo,          String
      attribute :enrollment,            ::Insured::Forms::EnrollmentForm
      attribute :family,                ::Insured::Forms::FamilyForm
      attribute :is_aptc_eligible,      Boolean
      attribute :market_kind,           String
      attribute :product,               ::Insured::Forms::ProductForm
      attribute :term_date,             Date
      attribute :elected_aptc_pct,      String
      attribute :available_aptc,        Float
      attribute :enable_tax_credit_btn, Boolean
      attribute :new_effective_on,      Date

      validates :market_kind,           presence: true

      def self.for_view(attrs)
        service     = self_term_or_cancel_service(attrs)
        form_params = service.find
        form_params.merge!(
          { available_aptc: fetch_available_aptc(attrs[:enrollment_id]),
            enable_tax_credit_btn: check_to_enable_tax_credit_btn}
        )
        new(form_params)
      end

      def self.check_to_enable_tax_credit_btn
        system_date = TimeKeeper.date_of_record
        begin_date = Date.new(system_date.year, 11, ::HbxProfile::IndividualEnrollmentDueDayOfMonth + 1).beginning_of_day
        end_date = begin_date.end_of_year.end_of_day
        (begin_date..end_date).cover?(system_date) ? false : true
      end

      def self.fetch_available_aptc(enr_id)
        ::Services::AvailableEligibilityService.new(enr_id, enr_id).available_eligibility[:total_available_aptc]
      end

      def self.for_post(attrs)
        service = self_term_or_cancel_service(attrs)
        service.term_or_cancel
      end

      def self.for_aptc_update_post(attrs)
        return 'Action cannot be performed because of the overlapping plan years.' unless check_to_enable_tax_credit_btn

        service = self_term_or_cancel_service(attrs)
        service.update_aptc
        'Successfully updated tax credits for enrollment.'
      end

      def self.self_term_or_cancel_service(attrs)
        ::Insured::Services::SelfTermOrCancelService.new(attrs)
      end

      def product
        hbx_enrollment.product
      end

      def hbx_enrollment
        enrollment&.hbx_enrollment
      end

      def special_enrollment_period
        hbx_enrollment.special_enrollment_period
      end
    end
  end
end
