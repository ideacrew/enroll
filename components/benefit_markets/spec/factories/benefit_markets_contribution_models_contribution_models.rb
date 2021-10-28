FactoryBot.define do
  factory :benefit_markets_contribution_models_contribution_model,
          class: 'BenefitMarkets::ContributionModels::ContributionModel' do
    sponsor_contribution_kind do
      '::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution'
    end
    contribution_calculator_kind do
      '::BenefitSponsors::ContributionCalculators::SimpleShopReferencePlanContributionCalculator'
    end
    title do
      "#{EnrollRegistry[:enroll_app].setting(:site_key).item.to_s.upcase} Shop Simple List Bill Contribution Model"
    end
    key { :zero_percent_sponsor_fixed_percent_contribution_model }
    many_simultaneous_contribution_units { true }

    member_relationships do
      [
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: 'employee',
          relationship_kinds: ['self']
        ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: 'spouse',
          relationship_kinds: ['spouse']
        ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: 'domestic_partner',
          relationship_kinds: %w[life_partner domestic_partner]
        ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: 'dependent',
          relationship_kinds: %w[
            child
            adopted_child
            foster_child
            stepchild
            ward
          ]
        )
      ]
    end

    contribution_units do
      contribution_factor =
        if self.key == :zero_percent_sponsor_fixed_percent_contribution_model
          0.0
        else
          0.5
        end

      [
        build(
          :benefit_markets_contribution_models_fixed_percent_contribution_unit,
          :with_member_relationship_maps,
          name: 'employee',
          display_name: 'Employee',
          order: 0,
          contribution_model: self,
          default_contribution_factor: contribution_factor,
          minimum_contribution_factor: contribution_factor,
          member_relationship_operator: :==
        ),
        build(
          :benefit_markets_contribution_models_fixed_percent_contribution_unit,
          :with_member_relationship_maps,
          name: 'spouse',
          display_name: 'Spouse',
          order: 1,
          contribution_model: self,
          default_contribution_factor: 0.0,
          minimum_contribution_factor: 0.0
        ),
        build(
          :benefit_markets_contribution_models_fixed_percent_contribution_unit,
          :with_member_relationship_maps,
          name: 'domestic_partner',
          display_name: 'Domestic Partner',
          order: 2,
          contribution_model: self,
          default_contribution_factor: 0.0,
          minimum_contribution_factor: 0.0
        ),
        build(
          :benefit_markets_contribution_models_fixed_percent_contribution_unit,
          :with_member_relationship_maps,
          name: 'dependent',
          display_name: 'Child Under 26',
          order: 3,
          contribution_model: self,
          default_contribution_factor: 0.0,
          minimum_contribution_factor: 0.0
        )
      ]
    end

    trait :for_health_single_product do
      # toDo
    end
  end
end
