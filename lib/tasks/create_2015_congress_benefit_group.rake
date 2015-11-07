namespace :congress do
  desc "Create 2015 & 2016 plan years and benefit groups for congress employers."
  task :create_plan_years => :environment do
    gold_2015 = Plan.valid_shop_by_metal_level_and_year("gold", "2015").collect(&:_id)
    # gold_2016 = Plan.valid_shop_by_metal_level_and_year("gold", "2016").collect(&:_id)
    congress_employer_feins = []
    plan_year_attributes = [
      {
        start_on: Date.new(2015, 1, 1),
        end_on: Date.new(2015, 12, 31),
        open_enrollment_start_on: Date.new(2014, 11, 9),
        open_enrollment_end_on: Date.new(2014, 12, 10),
        benefit_group_attributes: {
          title: "2015 Benefit Group",
          contribution_pct_as_int: 75,
          employee_max_amt: 437.69,
          first_dependent_max_amt: 971.90,
          over_one_dependents_max_amt: 971.90,
          reference_plan_id: gold_2015.first,
          elected_plan_ids: gold_2015,
          plan_option_kind: "metal_level", 
          is_congress: true
        }
      }#,
=begin  
      {
        start_on: Date.new(2016, 1, 1),
        end_on: Date.new(2016, 12, 31),
        open_enrollment_start_on: Date.new(2016, 11, 9),
        open_enrollment_end_on: Date.new(2016, 12, 13),
        benefit_group_attributes: {
          title: "2016 Benefit Group",
          contribution_pct_as_int: 75,
          employee_max_amt_in_cents: 462_30,
          first_dependent_max_amt_in_cents: 998_88,
          over_one_dependents_max_amt_in_cents: 1058_42,
          reference_plan_id: gold_2016.first,
          elected_plan_ids: gold_2016
        }
      }
=end
    ]
    relationship_benefit_attributes = [
      {
        relationship: :employee,
        premium_pct: 75,
        offered: true
      },
      {
        relationship: :spouse,
        premium_pct: 75,
        offered: true
      },
      {
        relationship: :domestic_partner,
        premium_pct: 0,
        offered: false
      },
      {
        relationship: :child_under_26,
        premium_pct: 75,
        offered: true
      },
      {
        relationship: :child_26_and_over,
        premium_pct: 75,
        offered: false
      }
    ]

    # Destroy all HBX Enrollments associated with Renewal

    ["536002522"].each do |fein|
      employer_profile = EmployerProfile.find_by_fein(fein)

      families = Family.all_enrollments_by_benefit_group_id(employer_profile.plan_years.first.benefit_groups.first.id)
      puts "families found #{families.count}"

      # renewed_families = families.select{|family| family.active_household.hbx_enrollments.size > 1}.count
      # puts "families with renewal enrollment #{renewed_families}"

      puts "deleting renewed plan year, assingments, enrollments"
      employer_profile.plan_years.renewing.each do |plan_year|
        renewing_bg_id = plan_year.benefit_groups.first.id

        families.each do |family|
          family.active_household.hbx_enrollments.renewing.each{|e| e.destroy}
        end

        employer_profile.census_employees.by_benefit_group_ids([renewing_bg_id]).each do |census_employee|
          census_employee.renewal_benefit_group_assignment.destroy
        end

        plan_year.destroy
      end

      active_benefit_group_id = employer_profile.plan_years.first.benefit_groups.first.id

      plan_year = nil
      if employer_profile.nil?
        puts "Unable to find employer profile for fein #{fein}"
      else
        plan_year_attributes.each do |plan_year_attribs|
          plan_year = PlanYear.new(plan_year_attribs.except(:benefit_group_attributes))
          employer_profile.plan_years = [plan_year]
          benefit_group = BenefitGroup.new(plan_year_attribs[:benefit_group_attributes])
          benefit_group.relationship_benefits =
            relationship_benefit_attributes.collect do |relationship_benefit_attribs|
              RelationshipBenefit.new(relationship_benefit_attribs)
            end
          plan_year.benefit_groups = [benefit_group]
        end
      end


      if plan_year.save
        puts "Successfully created plan year #{plan_year.start_on.year} for employer #{fein}."

        families.each do |family|
          family.active_household.hbx_enrollments.each do |e|
            e.benefit_group_id = plan_year.benefit_groups.first.id
            e.save!
          end
        end

        puts "Found #{employer_profile.census_employees.any_of(CensusEmployee.active.selector, CensusEmployee.waived.selector).count} census emloyees with old reference. Updating..."
        employer_profile.census_employees.any_of(CensusEmployee.active.selector, CensusEmployee.waived.selector).each do |census_employee|
          puts "updating ---#{census_employee}--#{census_employee.full_name} with id #{census_employee.id}"
          census_employee.active_benefit_group_assignment.update_attributes!(benefit_group_id: plan_year.benefit_groups.first.id)
        end

        employer_profile.application_expired! if employer_profile.registered?
        plan_year.publish!
      else
        puts plan_year.errors.full_messages.inspect
        puts "Error creating plan year #{plan_year.start_on.year} for employer #{fein}."
      end
    end
  end
end
