module FinancialAssistance
  module Services
    class FaaReviewService

      def initialize(application_id)
        @application_id = application_id
        @factory_class = ::FinancialAssistance::Factories::FaaReviewFactory
      end

      def find
        application = @factory_class.find(@application_id)
        attributes_to_form_params(application)
      end

      def attributes_to_form_params(obj)
        { :application_applicable_year => obj.family.application_applicable_year,
          :application => ::FinancialAssistance::Serializers::ApplicationSerializer.new(obj).to_hash }
      end
    end
  end
end
