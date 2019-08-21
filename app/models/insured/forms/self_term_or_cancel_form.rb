# frozen_string_literal: true

module Insured
  module Forms
    class SelfTermOrCancelForm
      include ActiveModel::Validations
      include Virtus.model

      attribute :carrier_logo,          String
      attribute :covered_members,       Array
      attribute :current_premium,       String
      attribute :enrollment,            ::Insured::Forms::EnrollmentForm
      attribute :is_under_ivl_oe,       Boolean
      attribute :market_kind,           String
      attribute :product,               ::Insured::Forms::ProductForm
      attribute :qle_kind_id,           String
      attribute :sep_id,                String
      attribute :should_term_or_cancel, String
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
        service     = self_term_or_cancel_service(attrs)
        form_params = service.term_or_cancel(:should_term_or_cancel)
      end

      def self.self_term_or_cancel_service(attrs)
        ::Insured::Services::SelfTermOrCancelService.new(attrs)
      end
    end
  end
end
