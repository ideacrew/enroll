namespace :migrations do
  desc "link employees with the roster"
  task :link_employees_with_roster => :environment do
    count  = 0
    failed = 0
    found  = 0

    Person.exists(:employee_roles => true).each do |p| 
      begin
        p.active_employee_roles.each do |active_employee_role|
          if !active_employee_role.census_employee.employee_role_linked?

            found += 1
            census_employee = active_employee_role.census_employee
            puts "----processing #{census_employee.full_name}"

            census_employee.employer_profile = active_employee_role.employer_profile
            census_employee.benefit_group_assignments.each do |bga|
              if bga.coverage_selected? && bga.hbx_enrollment.present? && !bga.hbx_enrollment.inactive?
                bga.hbx_enrollment.employee_role_id = active_employee_role.id
                bga.hbx_enrollment.save
              end
            end

            if !census_employee.valid?
              census_employee.benefit_group_assignments.each do |bg_assign|
                data_range = (bg_assign.benefit_group.start_on..bg_assign.benefit_group.end_on)

                if !data_range.cover?(bg_assign.start_on)
                  bg_assign.update_attributes(:start_on => bg_assign.benefit_group.start_on)
                end

                if bg_assign.end_on.present? && !data_range.cover?(bg_assign.end_on)
                  bg_assign.update_attributes(:end_on => bg_assign.benefit_group.end_on)
                end
              end
            end

            census_employee.employee_role = active_employee_role
            census_employee.save!
            puts "----processed #{census_employee.full_name}"
            count += 1
          end
        end
      rescue
        failed += 1
      end
    end

    puts "#{found} found, #{count} processed & #{failed} failed"
  end
end