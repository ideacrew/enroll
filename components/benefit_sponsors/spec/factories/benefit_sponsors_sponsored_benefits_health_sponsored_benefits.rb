FactoryBot.define do
  factory :benefit_sponsors_sponsored_benefits_health_sponsored_benefit, class: 'BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit', parent: :benefit_sponsors_sponsored_benefits_sponsored_benefit do
    sponsor_contribution { build(:benefit_sponsors_sponsored_benefits_sponsor_contribution) }

    transient do
      product_package { nil }
    end

    after(:build) do |sponsored_benefit, evaluator|
      if evaluator.product_package.present? && evaluator.product_package.products.present?
        sponsored_benefit.product_package_kind  = evaluator.product_package.package_kind
        sponsored_benefit.reference_product_id  = evaluator.product_package.products[0].id
        case evaluator.product_package.package_kind
        when :single_issuer
          sponsored_benefit.product_option_choice = evaluator.product_package.products[0].issuer_profile_id
        when :metal_level
          sponsored_benefit.product_option_choice = evaluator.product_package.products[0].metal_level_kind.to_sym
        end
        sponsored_benefit.sponsor_contribution = build(:benefit_sponsors_sponsored_benefits_sponsor_contribution, sponsored_benefit: sponsored_benefit, product_package: evaluator.product_package)
      end
    end
  end
end
