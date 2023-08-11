# frozen_string_literal: true

FactoryBot.define do
  factory :ivl_osse_eligibility_grant, class: "IvlOsseEligibilities::IvlOsseGrant" do

    title { 'Childcare Subsidy' }
    description { 'Osse Childcare Subsidy' }
    key { :contribution_grant }
    value do
      {
        title: 'childcare Subsidy',
        key: :childcare_grant,
        item: 'true'
      }
    end
  end
end