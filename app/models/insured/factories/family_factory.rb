# frozen_string_literal: true

module Insured
  module Factories
    class FamilyFactory

      attr_accessor :family_id, :family

      def initialize(family_id)
        self.family_id = family_id
      end

      def self.find(family_id)
        new(family_id).family
      end

      def family
        self.family = Family.find(BSON::ObjectId.from_string(family_id))
      end
    end
  end
end
