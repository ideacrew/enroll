FactoryGirl.define do
  factory :benefit_sponsors_benefit_sponsorship, class: 'BenefitSponsors::BenefitSponsorships::BenefitSponsorship' do

    source_kind   :self_serve

    initialize_with   {
        site  = create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca)
        organization  = build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)
        profile = organization.employer_profile
        sponsorship = profile.add_benefit_sponsorship
        sponsorship.rating_area = create(:benefit_markets_locations_rating_area)
        sponsorship
    }

    transient do
      initial_application_state :active
      renewal_application_state :enrollment_open
      default_effective_period nil
      default_open_enrollment_period nil
    end

    trait :with_benefit_market do
      benefit_market { FactoryGirl.build :benefit_markets_benefit_market}
    end

    trait :with_organization_dc_profile do
      after :build do |benefit_sponsorship, evaluator|
        profile = build(:benefit_sponsors_organizations_aca_shop_dc_employer_profile, organization: benefit_sponsorship.organization)
        benefit_sponsorship.profile = profile
      end
    end

    trait :with_organization_cca_profile do
      after :build do |benefit_sponsorship, evaluator|
        profile = build(:benefit_sponsors_organizations_aca_shop_cca_employer_profile, organization: benefit_sponsorship.organization)
        benefit_sponsorship.profile = profile
      end
    end

    trait :with_full_package do
      after :build do |benefit_sponsorship, evaluator|

      end
    end

    trait :with_market_profile do
      # we have to update the factory create instead of build
      before(:create) do |benefit_sponsorship, evaluator|

      end
    end

    trait :with_initial_benefit_application do
      after :build do |benefit_sponsorship, evaluator|
        FactoryGirl.build(:benefit_sponsors_benefit_application,
          :with_benefit_package,
          benefit_sponsorship: benefit_sponsorship,
          aasm_state: evaluator.initial_application_state,
          default_effective_period: evaluator.default_effective_period,
          default_open_enrollment_period: evaluator.default_open_enrollment_period
        )
      end
    end

    trait :with_renewal_benefit_application do
      after :build do |benefit_sponsorship, evaluator|
        benefit_application = FactoryGirl.build(:benefit_sponsors_benefit_application,
          :with_benefit_package,
          :with_predecessor_application,
          :benefit_sponsorship => benefit_sponsorship,
          :aasm_state => evaluator.renewal_application_state,
          :predecessor_application_state => evaluator.initial_application_state,
          :default_effective_period => evaluator.default_effective_period,
          :default_open_enrollment_period => evaluator.default_open_enrollment_period
        )

        # benefit_sponsorship.benefit_applications = [
        #   benefit_application, benefit_application.predecessor_application
        # ]
      end
    end

    trait :with_expired_and_active_benefit_application do
      after :build do |benefit_sponsorship, evaluator|
        benefit_application = FactoryGirl.build(:benefit_sponsors_benefit_application,
          :with_benefit_package,
          :with_active,
          :with_predecessor_expired_application,
          :benefit_sponsorship => benefit_sponsorship
        )

        benefit_sponsorship.benefit_applications = [
          benefit_application, benefit_application.predecessor_application
        ]
      end
    end

    trait :with_broker_agency_account do
      after :build do |benefit_sponsorship, evaluator|
        broker_agency_account = FactoryGirl.build :benefit_sponsors_accounts_broker_agency_account
        benefit_sponsorship.broker_agency_accounts= [broker_agency_account]
      end
    end

  end
end
