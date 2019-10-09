# frozen_string_literal: true

# require File.join(Rails.root, "lib/mongoid_migration_task")

class ImportIvlBenefitPackage < MongoidMigrationTask

  def migrate
    given_year = ENV["year"].to_i
    puts "::: Creating IVL #{given_year} benefit packages :::" unless Rails.env.test?
    # BenefitPackages - HBX 2021
    hbx = HbxProfile.current_hbx
    # create benefit package and benefit_coverage_period for 2021
    bc_period_prev = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == given_year - 1 }.first
    return if hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == given_year }
    bc_period = bc_period_prev.dup
    bc_period.title = "Individual Market Benefits #{given_year}"
    bc_period.start_on = bc_period_prev.start_on.next_year
    bc_period.end_on = bc_period_prev.end_on.next_year
    bc_period.open_enrollment_start_on = bc_period_prev.open_enrollment_start_on.next_year
    bc_period.open_enrollment_end_on = bc_period_prev.open_enrollment_end_on.next_year

    bs = hbx.benefit_sponsorship
    bs.benefit_coverage_periods << bc_period
    bs.save
  end
end
