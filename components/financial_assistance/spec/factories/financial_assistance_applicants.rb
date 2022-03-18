# frozen_string_literal: true

FactoryBot.define do
  factory :applicant, class: "FinancialAssistance::Applicant" do

    trait :with_student_information do
      is_student { true }
      student_kind { 'Full Time' }
      student_school_kind { 'Graduate School' }
      student_status_end_on { TimeKeeper.date_of_record.end_of_month.to_s }
    end
  end

  factory :financial_assistance_applicant, class: "FinancialAssistance::Applicant" do
    association :application

    is_active { true }
    is_ia_eligible { false }
    is_medicaid_chip_eligible { false }
    is_without_assistance { false }
    is_totally_ineligible { false }
    has_fixed_address { true }
    tax_filer_kind { "tax_filer" }
    relationship { nil }
    is_consumer_role { true }
    is_applying_coverage { true }
    is_claimed_as_tax_dependent { false }
    is_self_attested_blind { false }
    has_daily_living_help { false }
    need_help_paying_bills { false }
    gender { 'male' }

    trait :with_ssn do
      sequence(:ssn) { |n| 222_222_220 + n }
    end

    trait :with_work_email do
      emails { [FactoryBot.build(:financial_assistance_email, kind: "work")] }
    end

    trait :with_work_phone do
      phones { [FactoryBot.build(:financial_assistance_phone, kind: "work")] }
    end

    trait :male do
      gender { "male" }
    end

    trait :female do
      gender { "female" }
    end

    trait :child do
      relationship { 'child' }
    end

    trait :spouse do
      relationship { 'spouse' }
    end

    trait :with_student_information do
      is_student { true }
      student_kind { 'Full Time' }
      student_school_kind { 'Graduate School' }
      student_status_end_on { TimeKeeper.date_of_record.end_of_month.to_s }
    end

    trait :with_home_address do
      addresses { [FactoryBot.build(:financial_assistance_address)]}
    end

    trait :with_income_evidence do
      income_evidence { FactoryBot.build(:evidence, key: :income, title: 'Income', aasm_state: 'pending', is_satisfied: false) }
    end

    trait :with_esi_evidence do
      esi_evidence { FactoryBot.build(:evidence, key: :esi_mec, title: 'ESI MEC') }
    end

    trait :with_non_esi_evidence do
      non_esi_evidence { FactoryBot.build(:evidence, key: :non_esi_mec, title: 'Non ESI MEC') }
    end

    trait :with_local_mec_evidence do
      local_mec_evidence { FactoryBot.build(:evidence, key: :local_mec, title: 'Local MEC') }
    end
  end
end
