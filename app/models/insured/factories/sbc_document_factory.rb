# frozen_string_literal: true

module Insured
  module Factories
    class SbcDocumentFactory

      attr_accessor :id, :identifier, :document

      def initialize(id)
        self.id = id
      end

      def self.find(id)
        new(id).document
      end

      def document
        self.document = BenefitMarkets::Products::Product.where("sbc_document._id" => BSON::ObjectId.from_string(id.to_s)).first.sbc_document
      end
    end
  end
end
