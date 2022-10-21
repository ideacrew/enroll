# frozen_string_literal: true

FactoryBot.define do
  factory :qualifying_life_event_kind do

    title { "Married" }
    action_kind { "add" }
    edi_code { "32-MARRIAGE" }
    reason { "marriage" }
    market_kind { "shop" }
    effective_on_kinds { ["first_of_month"] }
    pre_event_sep_in_days { 0 }
    post_event_sep_in_days { 30 }
    is_self_attested { true }
    is_visible { true }
    event_kind_label {"event kind label"}
    ordinal_position { 15 }
    is_active { true }
    aasm_state {:active}
    tool_tip { "Enroll or add a family member because of marriage" }

    trait :effective_on_event_date do
      title { "Had a baby" }
      reason {"birth"}
      edi_code { "02-BIRTH" }
      effective_on_kinds { ["date_of_event"] }
      tool_tip { "Enroll or add a family member due to birth" }
    end

    trait :adoption do
      title { "Adopted a child" }
      reason {"adoption"}
      edi_code {"05-ADOPTION"}
      tool_tip {"Enroll or add a family member due to adoption"}
    end

    trait :domestic_partnership do
      title { "Entered into a legal domestic partnership" }
      reason {"domestic_partnership"}
      edi_code {"33-ENTERING DOMESTIC PARTNERSHIP"}
      tool_tip {"Entering a domestic partnership as permitted or recognized by the #{aca_state_name}"}
      effective_on_kinds {["first_of_next_month"]}
      ordinal_position { 3 }
    end

    trait :effective_on_first_of_month do
      title { "Married" }
      edi_code { "32-MARRIAGE" }
      reason { "marriage" }
      effective_on_kinds { ["first_of_next_month"] }
      tool_tip { "Enroll or add a family member because of marriage" }
    end

    trait :effective_on_fixed_first_of_next_month do
      title { "Losing other health insurance" }
      edi_code { "33-LOST ACCESS TO MEC" }
      reason { "lost_access_to_mec" }
      effective_on_kinds { ["fixed_first_of_next_month"] }
      tool_tip { "Someone in the household is losing other health insurance involuntarily" }
      event_kind_label {"Coverage end date"}
    end

    trait :effective_on_event_date_and_first_month do
      title { "Had a baby" }
      edi_code { "02-BIRTH" }
      effective_on_kinds { ["date_of_event", "first_of_next_month"] }
      tool_tip { "Enroll or add a family member due to birth" }
    end

    trait :medical_emergency do
      title { "A medical emergency prevented enrollment" }
      edi_code { "02-Emergency" }
      effective_on_kinds { ["first_of_month"] }
      tool_tip { "A medical emergency prevented enrollment" }
    end
  end
end
