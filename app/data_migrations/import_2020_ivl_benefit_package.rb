# require File.join(Rails.root, "lib/mongoid_migration_task")

 class Import2020IvlBenefitPackage < MongoidMigrationTask

   def migrate
    puts "::: Creating IVL 2020 benefit packages :::" unless Rails.env.test?
    # BenefitPackages - HBX 2020
    hbx = HbxProfile.current_hbx

     # create benefit package and benefit_coverage_period for 2020
    bc_period_2019 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2019 }.first
    unless bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2020 }
      bc_period = bc_period_2019.dup
      bc_period.title = "Individual Market Benefits 2020"
      bc_period.start_on = bc_period_2019.start_on.next_year
      bc_period.end_on = bc_period_2019.end_on.next_year
      bc_period.open_enrollment_start_on = bc_period_2019.open_enrollment_start_on.next_year

      # adding .last_month.end_of_month because in 2019 we updated the below date to Feb 8th.
      bc_period.open_enrollment_end_on = bc_period_2019.open_enrollment_end_on.next_year.beginning_of_year.end_of_month

       bs = hbx.benefit_sponsorship
      bs.benefit_coverage_periods << bc_period
      bs.save
    end
  end
end 
