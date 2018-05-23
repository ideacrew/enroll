FactoryGirl.define do

  sequence(:random_count) do |n|
    @random_counts ||= (1..25).to_a.shuffle
    @random_counts[n]
  end

  factory :benefit_sponsors_benefit_application, class: 'BenefitSponsors::BenefitApplications::BenefitApplication' do
    benefit_sponsorship { create(:benefit_sponsors_benefit_sponsorship, :with_full_package)}

    fte_count   FactoryGirl.generate(:random_count)
    pte_count   FactoryGirl.generate(:random_count)
    msp_count   FactoryGirl.generate(:random_count)

    # design using defining module spec helpers
    effective_period do
      start_on  = TimeKeeper.date_of_record.end_of_month + 1.day + 1.month
      end_on    = start_on + 1.year - 1.day
      start_on..end_on
    end

    open_enrollment_period do
      start_on = effective_period.min.prev_month
      end_on   = start_on + 9.days
      start_on..end_on
    end

    recorded_service_areas   { [create(:benefit_markets_locations_service_area)] }
    recorded_rating_area     { create(:benefit_markets_locations_rating_area) }

    trait :with_benefit_sponsor_catalog do
      after(:build) do |benefit_application, evaluator|
        if benefit_sponsorship = benefit_application.benefit_sponsorship
          benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.effective_period.min)
        end
        benefit_application.benefit_sponsor_catalog = (benefit_sponsor_catalog || ::BenefitMarkets::BenefitSponsorCatalog.new)
        benefit_application.benefit_sponsor_catalog.service_areas = benefit_sponsorship.service_areas
      end
    end

    trait :with_benefit_package do
      after(:build) do |benefit_application, evaluator|
        benefit_application.benefit_packages << create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application)
      end
    end

    trait :with_predecessor_application do
      after(:build) do |benefit_application, evaluator|
        benefit_application.predecessor_application = FactoryGirl.create(:benefit_sponsors_benefit_application,
          :with_benefit_package,
          benefit_sponsorship: benefit_application.benefit_sponsorship,
          effective_period: (benefit_application.effective_period.begin - 1.year)..(benefit_application.effective_period.end - 1.year),
          open_enrollment_period: (benefit_application.open_enrollment_period.begin - 1.year)..(benefit_application.open_enrollment_period.end - 1.year),
          successor_applications: [benefit_application],
          aasm_state: :active
        )
      end
    end

    trait :with_predecessor_expired_application do
      after(:build) do |benefit_application, evaluator|
        benefit_application.predecessor_application = FactoryGirl.create(:benefit_sponsors_benefit_application,
          :with_benefit_package,
          benefit_sponsorship: benefit_application.benefit_sponsorship,
          effective_period: (benefit_application.effective_period.begin - 1.year)..(benefit_application.effective_period.end - 1.year),
          open_enrollment_period: (benefit_application.open_enrollment_period.begin - 1.year)..(benefit_application.open_enrollment_period.end - 1.year),
          successor_applications: [benefit_application],
          aasm_state: :expired
        )
      end
    end

    trait :with_active do
      after(:build) do |benefit_application, evaluator|
        start_on  = TimeKeeper.date_of_record.end_of_month + 1.day - 3.months
        end_on    = start_on + 1.year - 1.day
        benefit_application.effective_period = start_on..end_on

        start_on = benefit_application.effective_period.min.prev_month
        end_on   = start_on + 9.days

        benefit_application.open_enrollment_period = start_on..end_on
        benefit_application.aasm_state = :active
      end
    end
  end
end
