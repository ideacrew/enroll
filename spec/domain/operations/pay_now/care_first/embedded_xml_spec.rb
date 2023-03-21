# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, "spec/shared_contexts/benchmark_products")
require "aca_entities/pay_now/care_first/operations/generate_xml"

RSpec.describe Operations::PayNow::CareFirst::EmbeddedXml do
  include_context "family with 2 family members with county_zip, rating_area & service_area"
  include_context "3 dental products with different rating_methods, different child_only_offerings and 3 health products"
  let(:enr_product) do
    product = BenefitMarkets::Products::DentalProducts::DentalProduct.by_year(TimeKeeper.date_of_record.year).detect(&:family_based_rating?)
    product.update_attributes!(dental_level: nil)
    product
  end

  let(:submitted_at) { 2.months.ago }
  let(:enrollment_kind) { "open_enrollment" }
  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :individual_unassisted,
                      effective_on: TimeKeeper.date_of_record.beginning_of_month,
                      terminated_on: TimeKeeper.date_of_record.end_of_month,
                      family: family,
                      product_id: enr_product.id,
                      rating_area_id: rating_area.id,
                      enrollment_kind: enrollment_kind,
                      coverage_kind: "dental",
                      submitted_at: submitted_at,
                      consumer_role_id: family.primary_person.consumer_role.id,
                      enrollment_members: family.family_members)
  end
  context "valid payload is created" do
    before do
      allow(::AcaEntities::PayNow::CareFirst::Operations::GenerateXml).to receive_message_chain("new.call").and_return(Dry::Monads::Result::Success.new("sample xml"))
    end
    it "should return successful xml" do
      expect(described_class.new.call(enrollment)).to be_success
    end
  end

  context "external xml function fails" do
    before do
      allow(::AcaEntities::PayNow::CareFirst::Operations::GenerateXml).to receive_message_chain("new.call").and_return(Dry::Monads::Result::Failure.new("unable to create xml"))
    end
    it "should return failure" do
      expect(described_class.new.call(enrollment)).to be_a(Dry::Monads::Result::Failure)
    end
  end
end
