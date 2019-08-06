# frozen_string_literal: true

module Insured
  module Services
    class SelfTermOrCancelService

      def initialize(enrollment_id)
        @enrollment_id = enrollment_id
        @factory_class = ::Insured::Factories::SelfServiceFactory
      end

      def find
        enrollment = @factory_class.find(@enrollment_id)
        attributes_to_form_params(enrollment)
      end

      def attributes_to_form_params(obj)
        {
          :enrollment => ::Insured::Serializers::EnrollmentSerializer.new(obj).to_hash
        }
      end
    end
  end
end
