# frozen_string_literal: true

module Insured
  module Factories
    class SelfServiceFactory

      attr_accessor :enrollment, :product, :family, :qle, :document, :sep

      def self.enrollment(enrollment_id)
        HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))
      end

      def self.product(product_id)
        ::BenefitMarkets::Products::HealthProducts::HealthProduct.find(BSON::ObjectId.from_string(product_id))
      end

      def self.family(family_id)
        Family.find(BSON::ObjectId.from_string(family_id))
      end

      def self.qle_kind(qle_id)
        QualifyingLifeEventKind.find(BSON::ObjectId.from_string(qle_id))
      end

      def self.sbc_document(sbc_id)
        BenefitMarkets::Products::Product.where("sbc_document._id" => BSON::ObjectId.from_string(sbc_id.to_s)).first.sbc_document
      end

      def self.sep(sep_id)
        SpecialEnrollmentPeriod.find(BSON::ObjectId.from_string(sep_id))
      end

    end
  end
end
