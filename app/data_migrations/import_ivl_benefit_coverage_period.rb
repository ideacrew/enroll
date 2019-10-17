# frozen_string_literal: true

# require File.join(Rails.root, "lib/mongoid_migration_task")

class ImportIvlBenefitCoveragePeriod < MongoidMigrationTask

  def migrate
    return puts "Please pass year as an argument to the script" if ENV["year"].blank?
    given_year = ENV["year"].to_i
    puts "::: Creating IVL #{given_year} benefit coverage period :::" unless Rails.env.test?
    hbx = HbxProfile.current_hbx
    if hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == given_year }.present?
      puts "Benefit coverage period already exists for #{given_year}"
    else
      bc_period_prev = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == given_year - 1 }.first
      bc_period = bc_period_prev.dup
      bc_period.title = "Individual Market Benefits #{given_year}"
      bc_period.start_on = bc_period_prev.start_on.next_year
      bc_period.end_on = bc_period_prev.end_on.next_year
      bc_period.open_enrollment_start_on = bc_period_prev.open_enrollment_start_on.next_year
      bc_period.open_enrollment_end_on = bc_period_prev.open_enrollment_end_on.next_year

      bs = hbx.benefit_sponsorship
      bs.benefit_coverage_periods << bc_period
      bs.save
      puts "Created benefit coverage period for year #{given_year}"
    end
  end
end
