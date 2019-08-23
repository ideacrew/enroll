# frozen_string_literal: true

module Insured
  module Forms
    class SelfTermOrCancelForm
      include ActiveModel::Validations
      include Virtus.model

      attribute :carrier_logo,          String
      attribute :current_premium,       String
      attribute :enrollment,            ::Insured::Forms::EnrollmentForm
      attribute :family,                ::Insured::Forms::FamilyForm
      attribute :is_aptc_eligible,      Boolean
      attribute :market_kind,           String
      attribute :product,               ::Insured::Forms::ProductForm
      attribute :term_date,             Date
      attribute :is_aptc_eligible,      Boolean

      validates :current_premium,       presence: true
      validates :market_kind,           presence: true

      def self.for_view(attrs)
        service     = self_term_or_cancel_service(attrs)
        form_params = service.find
        new(form_params)
      end

      def self.for_post(attrs)
        service = self_term_or_cancel_service(attrs)
        service.term_or_cancel(attrs[:term_or_cancel])
      end

      def self.self_term_or_cancel_service(attrs)
        ::Insured::Services::SelfTermOrCancelService.new(attrs)
      end
    end
  end
end
