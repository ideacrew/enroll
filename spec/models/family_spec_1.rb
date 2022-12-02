# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe ".current_enrolled_or_termed_products_by_subscriber", dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:household) { FactoryBot.create(:household, family: family) }
  let!(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
  let!(:effective_on) { TimeKeeper.date_of_record.beginning_of_month}
  let!(:subscriber_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id) }

  let!(:active_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      household: family.active_household,
                      coverage_kind: "health",
                      product: product,
                      aasm_state: 'coverage_selected',
                      hbx_enrollment_members: [subscriber_enrollment_member])
  end

  let!(:shopping_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      effective_on: effective_on,
                      household: family.active_household,
                      coverage_kind: "health",
                      aasm_state: 'shopping',
                      hbx_enrollment_members: [subscriber_enrollment_member])
  end

  context "when consumer has active enrollment" do
    it "should return current active enrolled product" do
      expect(family.current_enrolled_or_termed_products_by_subscriber(shopping_enrollment)).to eq [active_enrollment.product]
    end
  end

  context "when consumer has contionus coverage" do

    let!(:term_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        product: product,
                        terminated_on: effective_on - 1.day,
                        aasm_state: 'coverage_terminated',
                        hbx_enrollment_members: [subscriber_enrollment_member])
    end

    before do
      active_enrollment.cancel_coverage!
    end

    it "should return contionus coverage product" do
      expect(family.current_enrolled_or_termed_products_by_subscriber(shopping_enrollment)).to eq [term_enrollment.product]
    end
  end

  context "when consumer no contionus coverage" do

    let!(:term_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        product: product,
                        terminated_on: effective_on - 2.day,
                        aasm_state: 'coverage_terminated',
                        hbx_enrollment_members: [subscriber_enrollment_member])
    end

    before do
      active_enrollment.cancel_coverage!
    end

    it "should return []" do
      expect(family.current_enrolled_or_termed_products_by_subscriber(shopping_enrollment)).to eq []
    end
  end
end

describe ".current_enrolled_or_termed_products", dbclean: :after_each do
  let!(:effective_on) { TimeKeeper.date_of_record.beginning_of_month}

  let!(:person) { FactoryBot.create(:person)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:household) { FactoryBot.create(:household, family: family) }
  let!(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
  let!(:subscriber_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id) }

  let!(:person2) { FactoryBot.create(:person)}
  let!(:dependent_family_member) { FactoryBot.create(:family_member, family: family, person: person2) }
  let!(:dependent_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: dependent_family_member.id) }

  let!(:active_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      household: family.active_household,
                      coverage_kind: "health",
                      product: product,
                      aasm_state: 'coverage_selected',
                      hbx_enrollment_members: [subscriber_enrollment_member, dependent_enrollment_member])
  end

  let!(:shopping_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      effective_on: effective_on,
                      household: family.active_household,
                      coverage_kind: "health",
                      aasm_state: 'shopping',
                      hbx_enrollment_members: [dependent_enrollment_member])
  end

  context "when dependent has active enrollment" do

    it "should return current active enrolled product for dependent" do
      expect(family.current_enrolled_or_termed_products(shopping_enrollment)).to eq [active_enrollment.product]
    end
  end

  context "when dependent has contionus coverage" do

    let!(:term_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        product: product,
                        terminated_on: effective_on - 1.day,
                        aasm_state: 'coverage_terminated',
                        hbx_enrollment_members: [subscriber_enrollment_member, dependent_enrollment_member])
    end

    before do
      active_enrollment.cancel_coverage!
    end

    it "should return contionus coverage product" do
      expect(family.current_enrolled_or_termed_products(shopping_enrollment)).to eq [term_enrollment.product]
    end
  end

  context "when dependent or consumer has no contionus coverage" do

    let!(:term_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        product: product,
                        terminated_on: effective_on - 2.day,
                        aasm_state: 'coverage_terminated',
                        hbx_enrollment_members: [subscriber_enrollment_member])
    end

    before do
      active_enrollment.cancel_coverage!
    end

    it "should return []" do
      expect(family.current_enrolled_or_termed_products(shopping_enrollment)).to eq []
    end
  end
end

