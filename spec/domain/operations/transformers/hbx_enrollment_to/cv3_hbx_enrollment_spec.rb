# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/benchmark_products')

RSpec.describe ::Operations::Transformers::HbxEnrollmentTo::Cv3HbxEnrollment, dbclean: :around_each do
  include_context 'family with 2 family members with county_zip, rating_area & service_area'
  include_context '3 dental products with different rating_methods, different child_only_offerings and 3 health products'

  let(:enr_product) do
    product = BenefitMarkets::Products::DentalProducts::DentalProduct.by_year(TimeKeeper.date_of_record.year).detect(&:family_based_rating?)
    product.update_attributes!(dental_level: nil)
    product
  end

  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :individual_unassisted,
                      :with_enrollment_members,
                      effective_on: TimeKeeper.date_of_record.beginning_of_month,
                      family: family,
                      product_id: enr_product.id,
                      rating_area_id: rating_area.id,
                      coverage_kind: 'dental',
                      consumer_role_id: family.primary_person.consumer_role.id,
                      enrollment_members: family.family_members)
  end

  before do
    transformed_payload = subject.call(enrollment).success
    @validated_payload = AcaEntities::Contracts::Enrollments::HbxEnrollmentContract.new.call(transformed_payload).to_h
  end

  it 'returns with :slcsp_member_premium, :family_rated_premiums & :pediatric_dental_ehb' do
    expect(@validated_payload[:hbx_enrollment_members].first[:slcsp_member_premium]).not_to be_empty
    expect(@validated_payload[:product_reference][:family_rated_premiums]).not_to be_empty
    expect(@validated_payload[:product_reference][:pediatric_dental_ehb]).not_to be_nil
    expect(@validated_payload[:product_reference][:metal_level]).to eq(enr_product.metal_level_kind.to_s)
  end
end
