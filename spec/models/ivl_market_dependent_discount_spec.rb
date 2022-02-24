# frozen_string_literal: true

require "rails_helper"

describe UnassistedPlanCostDecorator, "given:
- a primary
- a spouse
- four children, not sorted by age (the oldest is last)
- health coverage in the IVL market
- coverage rate is not group-based
- child age limit setting set to 21
" do

  let(:coverage_start) { Date.new(2022,1,1) }

  let(:plan) do
    instance_double(
      BenefitMarkets::Products::HealthProducts::HealthProduct,
      "kind" => :health
    )
  end

  let(:enrollment) do
    instance_double(
      HbxEnrollment,
      :hbx_enrollment_members => hbx_enrollment_members,
      :effective_on => coverage_start,
      :rating_area => rating_area
    )
  end

  let(:elected_aptc) { 0.00 }

  let(:tax_household) do
    double
  end

  let(:child_age_limit) { 21 }

  let(:subscriber) do
    instance_double(
      HbxEnrollmentMember,
      {
        age_on_effective_date: 50,
        is_subscriber?: true,
        tobacco_use: nil
      }
    )
  end

  let(:spouse) do
    instance_double(
      HbxEnrollmentMember,
      {
        age_on_effective_date: 19,
        is_subscriber?: false,
        primary_relationship: "spouse",
        tobacco_use: nil
      }
    )
  end

  let(:last_child) do
    instance_double(
      HbxEnrollmentMember,
      {
        age_on_effective_date: 20,
        is_subscriber?: false,
        primary_relationship: "child",
        tobacco_use: nil
      }
    )
  end

  let(:youngest_child) do
    instance_double(
      HbxEnrollmentMember,
      {
        age_on_effective_date: 2,
        is_subscriber?: false,
        primary_relationship: "adopted_child",
        tobacco_use: nil
      }
    )
  end

  let(:child_2) do
    instance_double(
      HbxEnrollmentMember,
      {
        age_on_effective_date: 11,
        is_subscriber?: false,
        primary_relationship: "ward",
        tobacco_use: nil
      }
    )
  end

  let(:child_3) do
    instance_double(
      HbxEnrollmentMember,
      {
        age_on_effective_date: 9,
        is_subscriber?: false,
        primary_relationship: "stepchild",
        tobacco_use: nil
      }
    )
  end

  let(:hbx_enrollment_members) do
    [
      subscriber,
      spouse,
      youngest_child,
      child_2,
      child_3,
      last_child
    ]
  end

  subject do
    UnassistedPlanCostDecorator.new(
      plan,
      enrollment,
      elected_aptc,
      tax_household
    )
  end

  let(:enroll_app_settings) do
    double
  end

  let(:geographic_rating_area_model_item) do
    double(
      {
        item: "multi"
      }
    )
  end

  let(:child_age_limit_item) do
    double(
      {
        item: child_age_limit
      }
    )
  end

  let(:rating_area) do
    instance_double(
      BenefitMarkets::Locations::RatingArea,
      {
        exchange_provided_code: "ME0"
      }
    )
  end

  let(:zp_policy) do
    double(
      {
        disabled?: false
      }
    )
  end

  before :each do
    allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(enroll_app_settings)
    allow(EnrollRegistry).to receive(:[]).with(:zero_permium_policy).and_return(zp_policy)
    allow(enroll_app_settings).to receive(:setting).with(:geographic_rating_area_model).and_return(
      geographic_rating_area_model_item
    )
    allow(enroll_app_settings).to receive(:setting).with(:child_age_limit).and_return(
      child_age_limit_item
    )
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
      plan,
      coverage_start,
      50,
      "ME0",
      "NA"
    ).and_return(30.00)
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
      plan,
      coverage_start,
      19,
      "ME0",
      "NA"
    ).and_return(30.00)
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
      plan,
      coverage_start,
      20,
      "ME0",
      "NA"
    ).and_return(30.00)
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
      plan,
      coverage_start,
      2,
      "ME0",
      "NA"
    ).and_return(30.00)
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
      plan,
      coverage_start,
      11,
      "ME0",
      "NA"
    ).and_return(30.00)
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
      plan,
      coverage_start,
      9,
      "ME0",
      "NA"
    ).and_return(30.00)
  end

  it "applies a discount to the youngest child" do
    expect(subject.premium_for(youngest_child)).to eq 0.00
  end

  it "does not apply a discount to the last child" do
    expect(subject.premium_for(last_child)).not_to eq 0.00
  end

  it "applies discounts for no other members" do
    expect(subject.premium_for(subscriber)).not_to eq 0.00
    expect(subject.premium_for(spouse)).not_to eq 0.00
    expect(subject.premium_for(child_2)).not_to eq 0.00
    expect(subject.premium_for(child_3)).not_to eq 0.00
  end

end
