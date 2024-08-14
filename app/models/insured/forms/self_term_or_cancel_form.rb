# frozen_string_literal: true

module Insured
  module Forms
    class SelfTermOrCancelForm
      include ActiveModel::Validations
      include Virtus.model

      attribute :carrier_logo,                      String
      attribute :enrollment,                        ::Insured::Forms::EnrollmentForm
      attribute :family,                            ::Insured::Forms::FamilyForm
      attribute :is_aptc_eligible,                  Boolean
      attribute :market_kind,                       String
      attribute :product,                           ::Insured::Forms::ProductForm
      attribute :term_date,                         Date
      attribute :elected_aptc_pct,                  String
      attribute :available_aptc,                    Float
      attribute :enable_tax_credit_btn,             Boolean
      attribute :new_effective_on,                  Date
      attribute :default_tax_credit_value,          Float
      attribute :new_enrollment_premium,            Float
      attribute :max_tax_credit,                    Float
      attribute :cancellation_reason,               String

      validates :market_kind,                       presence: true

      def self.for_view(attrs)
        service     = self_term_or_cancel_service(attrs)
        status, error = service.validate_rating_address
        if status
          form_params = service.find
        else
          form = self.new
          form.errors.add(:base, error)
          return form
        end
        form_params.merge!({enable_tax_credit_btn: check_to_enable_tax_credit_btn(attrs)})
        new(form_params)
      end

      def self.check_to_enable_tax_credit_btn(attrs)
        enrollment = HbxEnrollment.find(attrs[:enrollment_id])
        new_effective_date = Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), enrollment.effective_on).to_date

        # Can't create a corresponding enrollment during the end of the year due to overlapping plan year issue and hence disabling the change tax credit button
        new_effective_date.year == enrollment.effective_on.year
      end

      def self.for_post(attrs)
        form = self.new
        attrs[:term_date] = format_date(attrs[:term_date])
        unless is_term_or_cancel_date_in_future?(attrs)
          form.errors.add(:base, 'Date cannot be in the past')
          return form
        end
        service = self_term_or_cancel_service(attrs)
        service.term_or_cancel
        form
      end

      def self.for_aptc_update_post(attrs)
        return 'Action cannot be performed because of the overlapping plan years.' unless check_to_enable_tax_credit_btn(attrs)

        service = self_term_or_cancel_service(attrs)
        service.update_aptc
        'Tax credit updated successfully.'
      end

      def self.self_term_or_cancel_service(attrs)
        ::Insured::Services::SelfTermOrCancelService.new(attrs)
      end

      def product
        hbx_enrollment&.product
      end

      def hbx_enrollment
        enrollment&.hbx_enrollment
      end

      def special_enrollment_period
        hbx_enrollment.special_enrollment_period
      end

      def self.is_term_or_cancel_date_in_future?(attrs)
        binding.irb
        return true unless attrs[:term_or_cancel] == 'terminate'

        date = Date.strptime(attrs[:term_date].to_s, "%m/%d/%Y")
        return date.today? || date.future?
      end

      def self.format_date(date_str)
        date_format = date_str.match(/\d{4}-\d{2}-\d{2}/) ? "%Y-%m-%d" : "%m/%d/%Y"
        date = Date.strptime(date_str, date_format)
        date.strftime("%m/%d/%Y")
      end
    end
  end
end
