namespace :seed do
  task :update_benefit_packages_for_native_americans => :environment do

    puts "*"*80
    puts "Updating native_american_health_benefits_2016 benefit package with csr_0"

    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2016 }.first
    ivl_health_plans_2016_for_csr_0 = Plan.individual_health_by_active_year_and_csr_kind(2016, "csr_0").entries.collect(&:_id)
    ivl_health_benefit_package_2016 = bc_period.benefit_packages.where(title: "native_american_health_benefits_2016").first
    ivl_health_benefit_package_2016.update_attributes(
      {
        benefit_ids: ivl_health_plans_2016_for_csr_0,
        benefit_eligibility_element_group: {
          cost_sharing: "csr_0"
        }
      }
    )

    puts "Complete"
    puts "*"*80

    puts "Updating native_american_dental_benefits_2016 with csr_0"
    ivl_dental_benefit_package_2016 = bc_period.benefit_packages.where(title: "native_american_dental_benefits_2016").first
    ivl_dental_benefit_package_2016.update_attributes(
      {
        benefit_eligibility_element_group: {
          cost_sharing: "csr_0"
        }
      }
    )
    puts "complete"
    puts "*"*80
    bc_period.save!

    puts "Updating native_american_health_benefits_2015 benefit package with csr_0"

    hbx_2015 = HbxProfile.find_by_state_abbreviation("dc")
    bc_period_2015 = hbx_2015.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2015 }.first
    ivl_health_plans_2015_for_csr_0 = Plan.individual_health_by_active_year_and_csr_kind(2015, "csr_0").entries.collect(&:_id)
    ivl_health_benefit_package_2015 = bc_period_2015.benefit_packages.where(title: "native_american_health_benefits_2015").first
    ivl_health_benefit_package_2015.update_attributes(
      {
        benefit_ids: ivl_health_plans_2015_for_csr_0,
        benefit_eligibility_element_group: {
          cost_sharing: "csr_0"
        }
      }
    )

    puts "Complete"
    puts "*"*80

    puts "Updating native_american_dental_benefits_2015 with csr_0"
    ivl_dental_benefit_package_2015 = bc_period_2015.benefit_packages.where(title: "native_american_dental_benefits_2015").first
    ivl_dental_benefit_package_2015.update_attributes(
      {
        benefit_eligibility_element_group: {
          cost_sharing: "csr_0"
        }
      }
    )
    bc_period_2015.save
    puts "complete"
    puts "*"*80

  end
end