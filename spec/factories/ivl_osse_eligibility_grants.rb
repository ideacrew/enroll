# frozen_string_literal: true

FactoryBot.define do
  factory :ivl_osse_eligibility_grant,
          class: "IvlOsseEligibilities::IvlOsseGrant" do
    title { "Hc4cc Subsidy" }
    description { "Hc4cc Subsidy Grant" }
    key { :hc4cc_subsidy }

    transient do
      from_state { :draft }
      to_state { :eligible }
      is_eligible { true }
      effective_on { TimeKeeper.date_of_record.beginning_of_month }
    end
  end
end
