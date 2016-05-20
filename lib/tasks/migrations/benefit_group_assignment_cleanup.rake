namespace :migrations do

  # desc "Cancel renewal for employer"
  # task :benefit_group_assignment_cleanup, [:fein] => [:environment] do |task, args|

  #   orgs = Organization.exists(:employer_profile => true)
  #   count = 0
  #   missing_count = 0
  #   orgs.each do |org|
  #     employer_profile = org.employer_profile
  #     census_employees = employer_profile.census_employees
  #     if employer_profile.active_plan_year && employer_profile.active_plan_year.coverage_period_contains?(TimeKeeper.date_of_record) && census_employees.size > 1
  #       benefit_group_ids = employer_profile.active_plan_year.benefit_groups.map(&:_id)
  #       census_employees.each do |census_employee|
  #         active_bg_assignment = census_employee.active_benefit_group_assignment

  #         if active_bg_assignment.present?
  #           if benefit_group_ids.include?(active_bg_assignment.benefit_group_id) && active_bg_assignment.initialized?
  #             bg_assignments = census_employee.benefit_group_assignments.where(:benefit_group_id.in => benefit_group_ids)
  #             if bg_assignments.where(:aasm_state.nin => ['initialized']).any?
  #               puts "#{census_employee.full_name}---#{employer_profile.legal_name}"
  #               count += 1
  #             end
  #           end
  #         else
  #           missing_count += 1
  #         end
  #       end
  #     end
  #   end
  #   puts count
  #   puts missing_count
  # end


  desc "Cleanup benefit group assignments which failed date gaurds"
  task :fix_benefit_group_assigments_with_invalid_dates => :environment do

    orgs = Organization.exists(:employer_profile => true)
    date_gaurds_failed = 0
    invalid_bgsm = 0
    
    puts "found #{orgs.size} employers"

    count = 0
    orgs.each do |org|
      next if ["536002522", "536002523", "536002558"].include?(org.fein)
      
      count += 1
      employer_profile = org.employer_profile
      employer_profile.census_employees.each do |ce|
        ce.benefit_group_assignments.each do |bg_assignment|
          next if bg_assignment.valid?
          invalid_bgsm += 1

          if benefit_group = bg_assignment.benefit_group
            date_range = benefit_group.start_on..benefit_group.end_on
            next if date_range.cover?(bg_assignment.start_on) && (bg_assignment.end_on.blank? || (bg_assignment.end_on.present? && date_range.cover?(bg_assignment.end_on)))

            if !date_range.cover?(bg_assignment.start_on)
              bg_assignment.start_on = date_range.begin
            end

            if bg_assignment.end_on.present? && !date_range.cover?(bg_assignment.end_on)
              bg_assignment.end_on = date_range.end
            end

            bg_assignment.save(:validate => false)
            puts "#{ce.full_name}---#{employer_profile.legal_name}---dates fixed"
          end
        end
      end

      if count % 100 == 0
        puts "processed #{count}"
      end
    end

    puts invalid_bgsm
    puts date_gaurds_failed
  end
end





