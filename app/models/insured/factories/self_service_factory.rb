# frozen_string_literal: true

module Insured
  module Factories
    class SelfServiceFactory

      attr_accessor :enrollment_id, :enrollment

      def initialize(enrollment_id)
        self.enrollment_id = enrollment_id
      end

      def self.find(enrollment_id)
        new(enrollment_id).enrollment
      end

      def enrollment
        self.enrollment = HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))
      end
    end
  end
end
