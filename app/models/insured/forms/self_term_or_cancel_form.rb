# frozen_string_literal: true

module Insured
  module Forms
    class SelfTermOrCancelForm
      include Virtus.model

      attribute :enrollment, HbxEnrollment
      attribute :term_date, Date

      def self.for_view(attrs)
        service = self_term_or_cancel_service(attrs[:enrollment_id])
        form_params = service.find
        new(form_params)
      end

      def self.self_term_or_cancel_service(enrollment_id)
        ::Insured::Services::SelfTermOrCancelService.new(enrollment_id)
      end
    end
  end
end
