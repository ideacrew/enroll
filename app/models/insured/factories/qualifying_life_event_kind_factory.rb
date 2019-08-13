# frozen_string_literal: true

module Insured
  module Factories
    class QualifyingLifeEventKindFactory

      attr_accessor :qle_id, :qle

      def initialize(qle_id)
        self.qle_id = qle_id
      end

      def self.find(qle_id)
        new(qle_id).qle
      end

      def qle
        self.qle = QualifyingLifeEventKind.find(BSON::ObjectId.from_string(qle_id))
      end
    end
  end
end
