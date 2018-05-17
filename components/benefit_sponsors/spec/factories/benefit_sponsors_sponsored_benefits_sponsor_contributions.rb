FactoryGirl.define do
  factory :benefit_sponsors_sponsored_benefits_sponsor_contribution, class: 'BenefitSponsors::SponsoredBenefits::SponsorContribution' do
    
    transient do 
      product_package nil
    end

    after(:build) do |sponsor_contribution, evaluator|
      if evaluator.product_package
        product_package =  evaluator.product_package
        if contribution_model = product_package.contribution_model
          contribution_model.contribution_units.each do |unit|
            build(:benefit_sponsors_sponsored_benefits_contribution_level,
              sponsor_contribution: sponsor_contribution,
              display_name: unit.display_name, is_offered: true, order: unit.order, 
              min_contribution_factor: unit.minimum_contribution_factor, 
              contribution_factor: unit.default_contribution_factor)
          end
        end
      end
    end
  end
end
