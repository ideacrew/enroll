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

  let(:submitted_at) { 2.months.ago }
  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :individual_unassisted,
                      effective_on: TimeKeeper.date_of_record.beginning_of_month,
                      terminated_on: TimeKeeper.date_of_record.end_of_month,
                      family: family,
                      product_id: enr_product.id,
                      rating_area_id: rating_area.id,
                      enrollment_kind: enrollment_kind,
                      coverage_kind: 'dental',
                      submitted_at: submitted_at,
                      consumer_role_id: family.primary_person.consumer_role.id,
                      enrollment_members: family.family_members)
  end

  let(:enrollment_kind) { 'open_enrollment' }
  let!(:enrollment_member) do
    FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id,
                                              eligibility_date: (TimeKeeper.date_of_record - 2.months), hbx_enrollment: enrollment,
                                              coverage_end_on: TimeKeeper.date_of_record.end_of_month)
  end

  before do
    ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
    ::BenefitMarkets::Products::ProductFactorCache.initialize_factor_cache!
  end

  context 'failure' do
    let(:tax_household_enrollment) { FactoryBot.create(:tax_household_enrollment, enrollment_id: enrollment.id)}

    before do
      allow(Operations::Transformers::TaxHouseholdEnrollmentTo::Cv3TaxHouseholdEnrollment).to receive_message_chain(:new, :call).with(tax_household_enrollment).and_return(Dry::Monads::Result::Failure.new("transform failed"))
    end

    it 'should return failure with error message' do
      result = subject.call(enrollment)
      expect(result).to be_failure
      expect(result.failure).to match("Could not transform tax household enrollment(s): [\"transform failed\"]")
    end
  end

  context 'when tax household enrollment is present' do
    let(:tax_household_enrollment) { FactoryBot.create(:tax_household_enrollment, enrollment_id: enrollment.id)}

    before do
      allow(Operations::Transformers::TaxHouseholdEnrollmentTo::Cv3TaxHouseholdEnrollment).to receive_message_chain(:new, :call).with(tax_household_enrollment).and_return(Dry::Monads::Result::Success.new(double))
    end

    it 'should return success with tax household enrollment' do
      result = subject.call(enrollment)
      expect(result.success?).to be_truthy
      expect(result.value!.keys.include?(:tax_households_references)).to be_truthy
    end
  end

  context 'slcsp' do
    before do
      transformed_payload = subject.call(enrollment).success
      @validated_payload = AcaEntities::Contracts::Enrollments::HbxEnrollmentContract.new.call(transformed_payload).to_h
    end

    let(:family_rated_premiums_result) do
      @validated_payload[:product_reference][:family_rated_premiums]
    end

    it 'returns with :slcsp_member_premium, :family_rated_premiums & :pediatric_dental_ehb' do
      expect(@validated_payload[:hbx_id]).to eq(enrollment.hbx_id.to_s)
      expect(@validated_payload[:terminated_on]).to eq(enrollment.terminated_on)
      expect(@validated_payload[:hbx_enrollment_members].first[:slcsp_member_premium]).not_to be_empty
      expect(@validated_payload[:hbx_enrollment_members].first[:coverage_end_on]).to eq enrollment_member.coverage_end_on
      expect(family_rated_premiums_result).not_to be_empty
      expect(family_rated_premiums_result[:primary_enrollee_two_dependents]).not_to be_nil
      expect(@validated_payload[:product_reference][:pediatric_dental_ehb]).not_to be_nil
      expect(@validated_payload[:product_reference][:metal_level]).to eq(enr_product.metal_level_kind.to_s)
    end
  end

  context 'for tobacco use' do
    let(:enr_product) do
      BenefitMarkets::Products::HealthProducts::HealthProduct.by_year(TimeKeeper.date_of_record.year).first
    end

    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :individual_unassisted,
                        effective_on: TimeKeeper.date_of_record.beginning_of_month,
                        terminated_on: TimeKeeper.date_of_record.end_of_month,
                        family: family,
                        product_id: enr_product.id,
                        rating_area_id: rating_area.id,
                        coverage_kind: 'health',
                        consumer_role_id: family.primary_person.consumer_role.id,
                        enrollment_members: family.family_members)
    end

    let!(:enrollment_member) do
      FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id,
                                                eligibility_date: (TimeKeeper.date_of_record - 2.months), hbx_enrollment: enrollment,
                                                coverage_end_on: TimeKeeper.date_of_record.end_of_month, tobacco_use: 'Y')
    end

    before do
      transformed_payload = subject.call(enrollment).success
      @validated_payload = AcaEntities::Contracts::Enrollments::HbxEnrollmentContract.new.call(transformed_payload).to_h
    end

    it 'should return :tobacoo_use, :non_tobacco_use_premium along with other attributes' do
      expect(@validated_payload[:hbx_id]).to eq(enrollment.hbx_id.to_s)
      expect(@validated_payload[:terminated_on]).to eq(enrollment.terminated_on)
      expect(@validated_payload[:hbx_enrollment_members].first[:tobacco_use]).to eq "Y"
      expect(@validated_payload[:hbx_enrollment_members].first[:non_tobacco_use_premium]).not_to be_empty
      expect(@validated_payload[:hbx_enrollment_members].first[:slcsp_member_premium]).not_to be_empty
      expect(@validated_payload[:hbx_enrollment_members].first[:coverage_end_on]).to eq enrollment_member.coverage_end_on
      expect(@validated_payload[:product_reference][:metal_level]).to eq(enr_product.metal_level_kind.to_s)
    end
  end

  context 'when special_enrollment_period is not present for a special enrollment' do
    let(:enrollment_kind) { 'special_enrollment' }

    let(:submitted_at) { TimeKeeper.date_of_record }
    let(:start_on) { submitted_at.prev_day }
    let(:special_enrollment_period) do
      build(
        :special_enrollment_period,
        family: family,
        qualifying_life_event_kind_id: qle.id,
        market_kind: "ivl",
        start_on: start_on,
        end_on: start_on.next_month
      )
    end

    let!(:add_special_enrollment_period) do
      family.special_enrollment_periods = [special_enrollment_period]
      family.save
    end
    let!(:qle)  { FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual") }

    before do
      transformed_payload = subject.call(enrollment.reload).success
      @validated_payload = AcaEntities::Contracts::Enrollments::HbxEnrollmentContract.new.call(transformed_payload).to_h
    end

    it 'should return special enrollment period reference along with other attributes' do
      expect(@validated_payload[:special_enrollment_period_reference][:qualifying_life_event_kind_reference][:title]).to eq(qle.title)
      expect(@validated_payload[:special_enrollment_period_reference][:start_on]).to eq(special_enrollment_period.start_on)
    end
  end

  context 'when special_enrollment is outside SEP_period' do
    let(:enrollment_kind) { 'special_enrollment' }

    let(:submitted_at) { TimeKeeper.date_of_record }
    let(:start_on) { submitted_at.prev_day }
    let(:special_enrollment_period) do
      build(
        :special_enrollment_period,
        family: family,
        qualifying_life_event_kind_id: qle.id,
        market_kind: "ivl",
        start_on: start_on,
        end_on: start_on
      )
    end

    let!(:add_special_enrollment_period) do
      family.special_enrollment_periods = [special_enrollment_period]
      family.save
    end
    let!(:qle)  { FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual") }

    before do
      transformed_payload = subject.call(enrollment.reload, {exclude_seps: true}).success
      @validated_payload = AcaEntities::Contracts::Enrollments::HbxEnrollmentContract.new.call(transformed_payload).to_h
    end

    context "when exclude_seps is passed to cv3 builder" do
      it 'should not return special enrollment period reference' do
        expect(@validated_payload[:special_enrollment_period_reference]).to be_nil
      end
    end
  end

  context 'when special_enrollment is outside SEP_period without exclude_seps parameter' do
    let(:enrollment_kind) { 'special_enrollment' }

    let(:submitted_at) { TimeKeeper.date_of_record }
    let(:start_on) { submitted_at.prev_day }
    let(:special_enrollment_period) do
      build(
        :special_enrollment_period,
        family: family,
        qualifying_life_event_kind_id: qle.id,
        market_kind: "ivl",
        start_on: start_on,
        end_on: start_on
      )
    end

    let!(:add_special_enrollment_period) do
      family.special_enrollment_periods = [special_enrollment_period]
      family.save
    end
    let!(:qle)  { FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual") }

    before do
      transformed_payload = subject.call(enrollment.reload).success
      @validated_payload = AcaEntities::Contracts::Enrollments::HbxEnrollmentContract.new.call(transformed_payload).to_h
    end

    context "when exclude_seps is passed to cv3 builder" do
      it 'should return hash block' do
        expect(@validated_payload[:special_enrollment_period_reference].class).to be(Hash)
      end

      it 'should not return special enrollment period reference' do
        expect(@validated_payload[:special_enrollment_period_reference].present?).to be_falsy
      end
    end
  end
end
