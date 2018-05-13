FactoryGirl.define do
  factory :benefit_sponsors_benefit_applications, class: 'BenefitSponsors::BenefitApplications::BenefitApplication' do
    benefit_sponsorship { create(:benefit_sponsors_benefit_sponsorship, :with_full_package)}

    # design using defining module spec helpers
    effective_period do
      effective_period_start_on = TimeKeeper.date_of_record.end_of_month + 1.day + 1.month
      effective_period_end_on = effective_period_start_on + 1.year - 1.day
      effective_period_start_on..effective_period_end_on
    end

    open_enrollment_period do
      effective_period_start_on = TimeKeeper.date_of_record.end_of_month + 1.day + 1.month
      open_enrollment_period_start_on = effective_period_start_on.prev_month
      open_enrollment_period_end_on = open_enrollment_period_start_on + 9.days
      open_enrollment_period_start_on..open_enrollment_period_end_on
    end
  end
end


