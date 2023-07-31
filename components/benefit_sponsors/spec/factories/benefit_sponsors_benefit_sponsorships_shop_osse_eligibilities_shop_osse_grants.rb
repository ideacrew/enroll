# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_benefit_sponsorships_shop_osse_eligibilities_shop_osse_grant,
          class:
            'BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant' do

    title { 'Contribution Subsidy' }
    description { 'Osse Contribution Subsidy' }
    key { :contribution_grant }
    value do
      {
        title: 'Contribution Subsidy',
        key: :contribution_grant,
        item: 'true'
      }
    end
  end
end
