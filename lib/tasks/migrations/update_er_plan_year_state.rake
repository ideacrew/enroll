class EmployerAppMigration



  def self.start_on_jan_1_employer_updates
    # 4. Joint Aid Management (38-2726350) - 2015 ref plan with 2016 PYs.... needs to be unpublished but has 2 EEs linked (no enrollments).  OK to try using Revert button or should EA team do it instead?
    # 3. Two Foxes LLC (46-4579728) - needs OE extended thru 12/10 (OE closed on 12/4,  no one enrolled)

    # 5. septcarres, llc (45-1657216) (#4256) - has two published PYs (one for 12/1/2015, one for 1/1/2016).  EEs blocked.  When we try to unpublish 2015 PY, it unpublishes the 2016 PY.
    # 1. Candace Ashley (62-1058763) - 2/1 draft PY, needs to be changed to 1/1 eff date and published
    # 2. Tricore Systems, LLC (47-2622751) - 2/1 draft PY, needs to be changed to 1/1 eff date and published
    # 6.  Baked by Yael (27-2812649) - 2/1 draft PY, needs to be changed to 1/1 eff date and published.(edited)

    [
      {
        employer_profile: {
            fein: "382726350", 
            plan_year: {
                start_on: Date.new(2016,1,1),
                end_on: Date.new(2016,12,31),
                open_enrollment_start_on: Date.new(2015,12,1),
                open_enrollment_end_on: Date.new(2015,12,14),
                imported_plan_year: true, 
              }
          }
        },

      # {
      #   employer_profile: {
      #       fein: "464579728", 
      #       plan_year: {
      #           open_enrollment_start_on: Date.new(2015,12,1),
      #           open_enrollment_end_on: Date.new(2015,12,14),
      #           imported_plan_year: true, 
      #         }
      #     }
      #   },

      # {
      #   employer_profile: {
      #       fein: "451657216", 
      #       plan_year: {
      #           start_on: Date.new(2016,1,1),
      #           end_on: Date.new(2016,12,31),
      #           open_enrollment_start_on: Date.new(2015,12,1),
      #           open_enrollment_end_on: Date.new(2015,12,14),
      #           imported_plan_year: true, 
      #         }
      #     }
      #   },

      # {
      #   employer_profile: {
      #       fein: "621058763", 
      #       plan_year: {
      #           start_on: Date.new(2016,1,1),
      #           end_on: Date.new(2016,12,31),
      #           open_enrollment_start_on: Date.new(2015,12,1),
      #           open_enrollment_end_on: Date.new(2015,12,14),
      #           imported_plan_year: true, 
      #         }
      #     }
      #   },

      # {
      #   employer_profile: {
      #       fein: "472622751", 
      #       plan_year: {
      #           start_on: Date.new(2016,1,1),
      #           end_on: Date.new(2016,12,31),
      #           open_enrollment_start_on: Date.new(2015,12,1),
      #           open_enrollment_end_on: Date.new(2015,12,14),
      #           imported_plan_year: true, 
      #         }
      #     }
      #   },

      # {
      #   employer_profile: {
      #       fein: "272812649", 
      #       plan_year: {
      #           start_on: Date.new(2016,1,1),
      #           end_on: Date.new(2016,12,31),
      #           open_enrollment_start_on: Date.new(2015,12,1),
      #           open_enrollment_end_on: Date.new(2015,12,14),
      #           imported_plan_year: true, 
      #         }
      #     }
      #   },
    ]
  end

  # def extend_oe_employer_profiles

  #   [
  #   ]
  # end

end

namespace :migrations do
  desc "Clear Employer's 2015 plan year and benefit groups"
  task :clear_2015_plan_years do

    # Only run this on initial employers

    EmployerAppMigration.start_on_jan_1_employer_updates.each do |update|

      employer_profile = EmployerProfile.find_by_fein(update[:employer_profile][:fein])
      puts "Updating employer: #{employer_profile.organization.legal_name}"

      census_employee_ids = CensusEmployee.by_employer_profile_id(employer_profile.id).map(&:id)

      plan_years = employer_profile.plan_years.select { |py| py.start_on.year == 2015 }
      plan_years.each do |py|
        puts "  clearing rostered EEs 2015 benefit groups"

        py.benefit_groups.each do |bg|
          census_employee_ids.each do |ce_id|
            census_employee = CensusEmployee.find(ce_id)

            census_employee.benefit_group_assignments.each do |bga|
              if bga.benefit_group.id == bg.id
                bga.destroy!
                census_employee.save!
                puts "  cleared #{census_employee.full_name} 2015 benefit group assignment"
              end
            end
          end
        end

        py.destroy!
        puts "  cleared #{census_employee.full_name} 2015 plan year"

      end
    end

  end
end

namespace :migrations do
  desc "Set Employer's plan year to correct state for employee enrollment"
  task :update_er_plan_year_state => :environment do

    record_count = 0
    updated_count = 0

    EmployerAppMigration.start_on_jan_1_employer_updates.each do |update|

      record_count += 1
      employer_profile = EmployerProfile.find_by_fein(update[:employer_profile][:fein])
      puts "Updating employer: #{employer_profile.organization.legal_name}"

      census_employee_ids = CensusEmployee.by_employer_profile_id(employer_profile.id).map(&:id)

      plan_years_2015 = employer_profile.plan_years.select { |py| py.start_on.year == 2015 }
      plan_years_2015.each do |py|
        puts "  clearing rostered EEs 2015 benefit groups"

        py.benefit_groups.each do |bg|
          census_employee_ids.each do |ce_id|
            census_employee = CensusEmployee.find(ce_id)
            census_employee.benefit_group_assignments = []
            census_employee.save!
            puts "  cleared #{census_employee.full_name} 2015 benefit group assignment"
          end
          py.destroy!
          puts "  cleared 2015 plan year"
        end
      end

      # plan_years_2016 = employer_profile.plan_years.select { |py| py.start_on.year == 2016 }
      # plan_years_2016.each { |py| py.destroy! if py.aasm_state == "enrolling" }
      plan_years_2016 = employer_profile.plan_years.select { |py| py.start_on.year == 2016 }

      if plan_years_2016.size == 1
        plan_year_2016 = plan_years_2016.first

        plan_year_2016.update_attributes(update[:employer_profile][:plan_year])

        census_employee_ids.each do |ce_id|
          census_employee = CensusEmployee.find(ce_id)
          census_employee.benefit_group_assignments = []
          # census_employee.add_benefit_group_assignment(plan_year_2016.benefit_groups.first, plan_year_2016.start_on)
          census_employee.save!
        end

        plan_year_2016.aasm_state = "draft"

        plan_year_2016.save
        puts "  plan year 2016 updated"
        updated_count += 1
      else
        if plan_years_2016.size == 0
          puts "  error: no plan_years matched for employer #{employer_profile[:fein]}"
        else
          puts "  error: multiple plan_years matched for employer  #{employer_profile[:fein]}"
        end
      end

      employer_profile.save
    end
      puts "*** processed #{record_count} employers and updated #{updated_count} plan years ***"

  end

  task :lksdflkj do
  end

end
