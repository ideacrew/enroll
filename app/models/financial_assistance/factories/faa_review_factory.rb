module FinancialAssistance
  module Factories
    class FaaReviewFactory

      attr_accessor :application_id, :application

      def initialize(application_id)
        self.application_id = application_id
      end

      def self.find(application_id)
        new(application_id).faa_application
      end

      def faa_application
        self.application = ::FinancialAssistance::Application.find(BSON::ObjectId.from_string(application_id))
      end
    end
  end
end
