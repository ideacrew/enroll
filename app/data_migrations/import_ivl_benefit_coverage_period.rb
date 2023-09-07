# frozen_string_literal: true

# require File.join(Rails.root, "lib/mongoid_migration_task")

class ImportIvlBenefitCoveragePeriod < MongoidMigrationTask

  def migrate
    return puts "Please pass year as an argument to the script" if ENV["year"].blank?
    given_year = ENV["year"].to_i
    puts "::: Creating IVL #{given_year} benefit coverage period :::" unless Rails.env.test?
    hbx = HbxProfile.current_hbx
    if hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == given_year }.present?
      puts "Benefit coverage period already exists for #{given_year}" unless Rails.env.test?
    else
      hbx.benefit_sponsorship.create_benefit_coverage_period(given_year)
      puts "Created benefit coverage period for year #{given_year}" unless Rails.env.test?
    end
  end
end
