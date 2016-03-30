module Factories
  class PlanYearFactory
    def self.default_dates_for_coverage_starting_on(coverage_start_date)
      plan_year_start_on = coverage_start_date
      plan_year_end_on = coverage_start_date + 1.year - 1.day
      open_enrollment_start_on = plan_year_start_on - 2.months
      open_enrollment_end_on = Date.new(open_enrollment_start_on.year, open_enrollment_start_on.month, Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on)
      {
        start_on: plan_year_start_on,
        end_on: plan_year_end_on,
        open_enrollment_start_on: open_enrollment_start_on,
        open_enrollment_end_on: open_enrollment_end_on
      }
    end
  end
end
