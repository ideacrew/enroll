namespace :seed do
  task :revert_benefit_packages_for_native_americans => :environment do

    puts "*"*80
    puts "revert native_american_health_benefits_2016 benefit package"

    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2016 }.first
    ivl_health_plans_2016 = Plan.individual_health_by_active_year(2016).health_metal_nin_catastropic.entries.collect(&:_id)
    ivl_health_benefit_package_2016 = bc_period.benefit_packages.where(title: "native_american_health_benefits_2016").first
    ivl_health_benefit_package_2016.attributes =
    (
      {
        benefit_ids: ivl_health_plans_2016,
        benefit_eligibility_element_group: {
          cost_sharing: ""
        }
      }
    )
    bc_period.save!
    puts "Complete"
    puts "*"*80

    puts "Updating native_american_dental_benefits_2016"
    ivl_dental_benefit_package_2016 = bc_period.benefit_packages.where(title: "native_american_dental_benefits_2016").first
    ivl_dental_benefit_package_2016.attributes = (
      {
        benefit_eligibility_element_group: {
          cost_sharing: ""
        }
      }
    )
    bc_period.save!
    puts "complete"
    puts "*"*80

    puts "Updating native_american_health_benefits_2015 benefit package"
    hbx_2015 = HbxProfile.find_by_state_abbreviation("dc")
    bc_period_2015 = hbx_2015.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2015 }.first
    ivl_health_plans_2015 = Plan.individual_health_by_active_year(2015).health_metal_nin_catastropic.entries.collect(&:_id)
    ivl_health_benefit_package_2015 = bc_period_2015.benefit_packages.where(title: "native_american_health_benefits_2015").first
    ivl_health_benefit_package_2015.attributes = (
      {
        benefit_ids: ivl_health_plans_2015,
        benefit_eligibility_element_group: {
          cost_sharing: ""
        }
      }
    )
    bc_period_2015.save!
    puts "Complete"
    puts "*"*80

    puts "Updating native_american_dental_benefits_2015"
    ivl_dental_benefit_package_2015 = bc_period_2015.benefit_packages.where(title: "native_american_dental_benefits_2015").first
    ivl_dental_benefit_package_2015.attributes = (
      {
        benefit_eligibility_element_group: {
          cost_sharing: ""
        }
      }
    )
    bc_period_2015.save!
    puts "complete"
    puts "*"*80

  end
end
