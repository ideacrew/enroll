# frozen_string_literal: true

FactoryBot.define do
  factory :hbx_enrollment do
    household { family.households.first }
    family
    kind { "employer_sponsored" }
    elected_premium_credit { 0 }
    applied_premium_credit { 0 }
    effective_on {1.month.ago.to_date}
    terminated_on { nil }
    waiver_reason { "this is the reason" }
    # broker_agency_id nil
    # writing_agent_id nil
    submitted_at {2.months.ago}
    aasm_state { "coverage_selected" }
    aasm_state_date {effective_on}
    updated_by { "factory" }
    is_active { true }
    enrollment_kind { "open_enrollment" }
    # comments

    transient do
      enrollment_members { [] }
      active_year { TimeKeeper.date_of_record.year }
    end

    plan { create(:plan, :with_rating_factors, :with_premium_tables, active_year: active_year) }

    trait :with_enrollment_members do
      hbx_enrollment_members do
        enrollment_members.map do |member|
          FactoryBot.build(:hbx_enrollment_member, applicant_id: member.id, hbx_enrollment: self, is_subscriber: member.is_primary_applicant, coverage_start_on: self.effective_on, eligibility_date: self.effective_on)
        end
      end
    end

    trait :with_aptc_enrollment_members do
      hbx_enrollment_members do
        enrollment_members.map do |member|
          FactoryBot.build(:hbx_enrollment_member, applicant_id: member.id, hbx_enrollment: self, is_subscriber: member.is_primary_applicant, coverage_start_on: self.effective_on, eligibility_date: self.effective_on, applied_aptc_amount: 1500)
        end
      end
    end

    trait :with_tobacco_use_enrollment_members do
      hbx_enrollment_members do
        enrollment_members.map do |member|
          FactoryBot.build(:hbx_enrollment_member, applicant_id: member.id, hbx_enrollment: self, is_subscriber: member.is_primary_applicant, coverage_start_on: self.effective_on, eligibility_date: self.effective_on, tobacco_use: 'Y')
        end
      end
    end

    trait :with_dental_coverage_kind do
      association :plan, factory: [:plan, :with_dental_coverage]
      coverage_kind { "dental" }
    end

    trait :individual_aptc do
      kind                { 'individual' }
      effective_on        { TimeKeeper.date_of_record.beginning_of_month }
      coverage_kind       { 'health' }
      applied_aptc_amount { 150.00 }
      elected_aptc_pct    { 1.00 }
      aasm_state          { 'coverage_selected' }
    end

    trait :individual_unassisted do
      kind { "individual" }
      elected_premium_credit { 0 }
      applied_premium_credit { 0 }
      aasm_state { "coverage_selected" }
    end

    trait :individual_shopping do
      kind { 'individual' }
      aasm_state { 'shopping' }
    end

    trait :individual_assisted do
      kind { "individual" }
      elected_premium_credit { 150 }
      applied_premium_credit { 110 }
      aasm_state { "coverage_selected" }
    end

    trait :shop do
      kind { "employer_sponsored" }
      aasm_state { "coverage_selected" }
    end

    trait :cobra_shop do
      kind { "employer_sponsored_cobra" }
      aasm_state { "coverage_selected" }
    end

    trait :health_plan do
      active_individual_health_plan
    end

    trait :dental_plan do
      active_individual_dental_plan
    end

    trait :catastrophic_plan do
      active_individual_catastophic_plan
    end

    trait :csr_87_plan do
      active_csr_87_plan
    end

    trait :active_csr_00_plan do
      active_csr_00_plan
    end

    trait :with_product do
      product {  FactoryBot.create(:benefit_markets_products_product) }
    end

    trait :with_silver_health_product do
      product { FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :silver)}
    end

    trait :with_health_product do
      product { FactoryBot.create(:benefit_markets_products_health_products_health_product)}
    end

    trait :with_dental_product do
      coverage_kind { "dental" }
      product { FactoryBot.create(:benefit_markets_products_dental_products_dental_product)}
    end

    trait :coverage_selected do
      aasm_state { "coverage_selected" }
    end

    trait :open_enrollment do
      enrollment_kind  { "open_enrollment" }
    end

    trait :special_enrollment do
      enrollment_kind { special_enrollment }
    end

    trait :terminated do
      aasm_state { "coverage_terminated" }
      terminated_on { Time.now.last_month.end_of_month }
      termination_submitted_on { TimeKeeper.date_of_record }
    end

    trait :older_effective_date do
      effective_on {Date.new(active_year,4,1)}
    end

    trait :newer_effective_date do
      effective_on {Date.new(active_year,5,1)}
    end

    factory :individual_qhp_enrollment,          traits: [:individual_unassisted, :health_plan]
    factory :individual_qdp_enrollment,          traits: [:individual_unassisted, :dental_plan]
    factory :individual_assisted_qhp_enrollment, traits: [:individual_assisted, :health_plan]
    factory :individual_csr_00_enrollment,       traits: [:individual_assisted, :active_csr_00_plan, :health_plan]
    factory :individual_csr_87_enrollment,       traits: [:individual_assisted, :active_csr_87_plan, :health_plan]
    factory :individual_catastrophic_enrollment, traits: [:individual_assisted, :catastrophic_plan, :health_plan]
    factory :shop_health_enrollment,             traits: [:shop, :health_plan]
    factory :individual_qhp_enrollment_apr1,  traits: [:individual_unassisted, :older_effective_date, :with_enrollment_members]
    factory :individual_qhp_enrollment_may1,  traits: [:individual_unassisted, :newer_effective_date, :with_enrollment_members]
  end

  FactoryBot.define do
    factory(:individual_market_health_enrollment, class: HbxEnrollment) do
      transient do
        primary_person { FactoryBot.create(:person, :with_consumer_role) }
      end

      family_members do
        [
                         FactoryBot.create(:family_member, family: self, is_primary_applicant: true, is_active: true, person: primary_person)
      ]
      end

      hbx_enrollment_members do
        []
      end


      after :create do |f, _evaluator|
        f.households.first.add_household_coverage_member(f.family_members.first)
      end
    end
  end

end
