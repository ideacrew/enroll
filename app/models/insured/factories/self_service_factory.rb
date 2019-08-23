# frozen_string_literal: true

module Insured
  module Factories
    class SelfServiceFactory
      attr_accessor :document_id, :enrollment_id, :family_id, :product_id, :qle_id, :sep_id

      def initialize(args)
        self.document_id   = args[:document_id] || nil
        self.enrollment_id = args[:enrollment_id] || nil
        self.family_id     = args[:family_id] || nil
        self.product_id    = args[:product_id] || nil
        self.qle_id        = args[:qle_id] || nil
        self.sep_id        = args[:sep_id] || nil
      end

      def self.find(enrollment_id, family_id)
        new({enrollment_id: enrollment_id, family_id: family_id}).build_form_params
      end

      def build_form_params
        enrollment = self.class.enrollment(enrollment_id)
        family     = Family.find(BSON::ObjectId.from_string(family_id))
        sep        = SpecialEnrollmentPeriod.find(BSON::ObjectId.from_string(family.latest_active_sep.id))
        qle        = QualifyingLifeEventKind.find(BSON::ObjectId.from_string(sep.qualifying_life_event_kind_id))
        return { enrollment: enrollment, family: family, qle: qle }
      end


      def self.enrollment(enrollment_id)
        HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))
      end

      def self.family(family_id)
        Family.find(BSON::ObjectId.from_string(family_id))
      end

      def self.sbc_document(sbc_id)
        BenefitMarkets::Products::Product.where("sbc_document._id" => BSON::ObjectId.from_string(sbc_id.to_s)).first.sbc_document
      end

    end
  end
end
