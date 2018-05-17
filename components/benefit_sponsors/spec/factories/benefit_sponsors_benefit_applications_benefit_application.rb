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

    recorded_service_area  { ::BenefitMarkets::Locations::ServiceArea.new }
    recorded_rating_area   { ::BenefitMarkets::Locations::RatingArea.new }

    trait :with_benefit_sponsor_catalog do
      after(:build) do |benefit_application, evaluator|
        if benefit_sponsorship = benefit_application.benefit_sponsorship
          benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.effective_period.min)
        end
        benefit_application.benefit_sponsor_catalog = (benefit_sponsor_catalog || ::BenefitMarkets::BenefitSponsorCatalog.new)
      end
    end
  end
end
