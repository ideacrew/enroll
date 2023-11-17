# frozen_string_literal: true

FactoryBot.define do
  factory :ivl_osse_eligibility_grant, class: "IvlOsseEligibilities::IvlOsseGrant" do

    title { 'Childcare Subsidy' }
    description { 'Osse Childcare Subsidy' }
    key { :contribution_grant }
    value do
      {
        title: 'childcare Subsidy',
        key: :aca_individual_osse_plan_subsidy,
        item: 'aca_individual_osse_plan_subsidy'
      }
    end
  end
end
