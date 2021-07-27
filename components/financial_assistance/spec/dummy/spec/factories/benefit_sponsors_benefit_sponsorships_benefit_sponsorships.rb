# frozen_string_literal: true

# rubocop:disable all

FactoryBot.define do
  factory :benefit_sponsors_benefit_sponsorship, class: 'BenefitSponsorship' do

    source_kind   { :self_serve }

    transient do
      initial_application_state { :active }
      renewal_application_state { :enrollment_open }
      draft_application_state { :draft }
      default_effective_period { nil }
      default_open_enrollment_period { nil }
      service_area_list { [] }
      supplied_rating_area { nil }
      site { nil }
    end

    trait :with_benefit_market do
      benefit_market { FactoryBot.build :benefit_markets_benefit_market}
    end

    trait :with_rating_area do
      after :build do |benefit_sponsorship, evaluator|
        benefit_sponsorship.rating_area = (evaluator.supplied_rating_area || create(:benefit_markets_locations_rating_area))
      end
    end

    trait :with_service_areas do
      after :build do |benefit_sponsorship, evaluator|
        benefit_sponsorship.service_areas =
          if evaluator.service_area_list.any?
            evaluator.service_area_list
          else
            [create(:benefit_markets_locations_service_area)]
          end
      end
    end

    trait :with_previous_year_rating_area do
      after :build do |benefit_sponsorship, evaluator|
        benefit_sponsorship.rating_area = evaluator.supplied_rating_area || create(:benefit_markets_locations_rating_area, active_year: TimeKeeper.date_of_record.prev_year.year)
      end
    end

    trait :with_previous_year_service_areas do
      after :build do |benefit_sponsorship, evaluator|
        benefit_sponsorship.service_areas =
          if evaluator.service_area_list.any?
            evaluator.service_area_list
          else
            [create(:benefit_markets_locations_service_area, active_year: TimeKeeper.date_of_record.prev_year.year)]
          end
      end
    end

    trait :with_organization_dc_profile do
      after :build do |benefit_sponsorship, _evaluator|
        profile = build(:benefit_sponsors_organizations_aca_shop_dc_employer_profile, organization: benefit_sponsorship.organization)
        benefit_sponsorship.profile = profile
      end
    end

    trait :with_organization_cca_profile do
      after :build do |benefit_sponsorship, evaluator|
        site = nil
        site = evaluator.site || BenefitSponsors::Site.by_site_key(:cca).first || create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca)
        organization = create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)
        benefit_sponsorship.benefit_market = site.benefit_markets.first
        profile = organization.employer_profile
        benefit_sponsorship.profile = profile
      end
    end

    trait :with_full_package do
      with_organization_cca_profile
      after :build do |benefit_sponsorship, evaluator|

      end
    end

    trait :with_market_profile do
      with_organization_cca_profile
      # we have to update the factory create instead of build
      before(:create) do |benefit_sponsorship, evaluator|

      end
    end

    trait :with_initial_benefit_application do
      after :build do |benefit_sponsorship, evaluator|
        FactoryBot.build(:benefit_sponsors_benefit_application,
                         :with_benefit_package,
                         benefit_sponsorship: benefit_sponsorship,
                         aasm_state: evaluator.initial_application_state,
                         default_effective_period: evaluator.default_effective_period,
                         default_open_enrollment_period: evaluator.default_open_enrollment_period)
      end
    end

    trait :with_renewal_benefit_application do
      after :build do |benefit_sponsorship, evaluator|
        benefit_application = FactoryBot.build(:benefit_sponsors_benefit_application,
                                               :with_benefit_package,
                                               :with_predecessor_application,
                                               :benefit_sponsorship => benefit_sponsorship,
                                               :aasm_state => evaluator.renewal_application_state,
                                               :predecessor_application_state => evaluator.initial_application_state,
                                               :default_effective_period => evaluator.default_effective_period,
                                               :default_open_enrollment_period => evaluator.default_open_enrollment_period)

        # benefit_sponsorship.benefit_applications = [
        #   benefit_application, benefit_application.predecessor_application
        # ]
      end
    end

    trait :with_expired_and_active_benefit_application do
      after :build do |benefit_sponsorship, _evaluator|
        benefit_application = FactoryBot.build(:benefit_sponsors_benefit_application,
                                               :with_benefit_package,
                                               :with_active,
                                               :with_predecessor_expired_application,
                                               :benefit_sponsorship => benefit_sponsorship)

        benefit_sponsorship.benefit_applications = [
          benefit_application, benefit_application.predecessor_application
        ]
      end
    end

    trait :with_imported_and_renewal_benefit_application do
      after :build do |benefit_sponsorship, evaluator|
        benefit_application = FactoryBot.build(:benefit_sponsors_benefit_application,
                                               :with_benefit_package,
                                               :with_predecessor_imported_application,
                                               :benefit_sponsorship => benefit_sponsorship,
                                               :aasm_state => evaluator.renewal_application_state,
                                               :predecessor_application_state => evaluator.initial_application_state,
                                               :default_effective_period => evaluator.default_effective_period,
                                               :default_open_enrollment_period => evaluator.default_open_enrollment_period)
      end
    end

    trait :with_renewal_draft_benefit_application do
      after :build do |benefit_sponsorship, evaluator|
        benefit_application = FactoryBot.build(:benefit_sponsors_benefit_application,
                                               :with_benefit_package,
                                               :with_predecessor_application,
                                               :benefit_sponsorship => benefit_sponsorship,
                                               :aasm_state => evaluator.draft_application_state,
                                               :predecessor_application_state => evaluator.initial_application_state,
                                               :default_effective_period => evaluator.default_effective_period,
                                               :default_open_enrollment_period => evaluator.default_open_enrollment_period)
      end
    end

    trait :with_broker_agency_account do
      transient do
        broker_agency_profile { nil }
      end

      after :build do |benefit_sponsorship, evaluator|
        if evaluator.broker_agency_profile
          broker_agency_account = FactoryBot.build :benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: evaluator.broker_agency_profile, benefit_sponsorship: benefit_sponsorship
          benefit_sponsorship.broker_agency_accounts = [broker_agency_account]
        else
          broker_agency_account = FactoryBot.build :benefit_sponsors_accounts_broker_agency_account, benefit_sponsorship: benefit_sponsorship
          benefit_sponsorship.broker_agency_accounts = [broker_agency_account]
        end
      end
    end

  end
end

# rubocop:enable all

