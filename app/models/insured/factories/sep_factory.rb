# frozen_string_literal: true

module Insured
  module Factories
    class SepFactory

      attr_accessor :sep_id, :sep

      def initialize(sep_id)
        self.sep_id = sep_id
      end

      def self.find(sep_id)
        new(sep_id).sep
      end

      def sep
        self.sep = SpecialEnrollmentPeriod.find(BSON::ObjectId.from_string(sep_id))
      end
    end
  end
end
