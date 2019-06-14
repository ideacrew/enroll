# frozen_string_literal: true
module FinancialAssistance
  module Forms
    class FaaReviewForm
      include Virtus.model

      attribute :application, ApplicationForm
      attribute :application_applicable_year, Integer

      def self.for_view(attrs)
        service = faa_review_service(attrs[:id])
        form_params = service.find
        new(form_params)
      end

      def self.faa_review_service(appli_id)
        ::FinancialAssistance::Services::FaaReviewService.new(appli_id)
      end

    end
  end
end
