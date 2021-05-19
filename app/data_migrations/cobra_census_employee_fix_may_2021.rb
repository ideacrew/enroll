# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# A class to fix missing cobra enrollments
class CobraCensusEmployeeFixMay2021 < MongoidMigrationTask
  def migrate
    file_name = ENV['file_name'].to_s
    CSV.foreach("#{Rails.root}/#{file_name}", headers: true) do |row|
      employee_data = row.to_h.with_indifferent_access
      person = Person.where(hbx_id: employee_data['employee_hbx_id']).first
      if person.present?
        employee_role = person.employee_roles.detect { |er| er.employer_profile.hbx_id == employee_data[:employer_hbx_id] }
        if employee_role.present?
          census_employee = employee_role.census_employee
          cobra_date = Date.strptime(employee_data[:cobra_start_date], "%m/%d/%Y")
          begin
            if census_employee.may_elect_cobra?
              census_employee.update_for_cobra(cobra_date, nil)
              puts("Sucessfully created Cobra enrollment for person with hbx_id: #{employee_data['employee_hbx_id']}")
            elsif census_employee.aasm_state == "cobra_linked" && !(ActiveModel::Type::Boolean.new.cast(employee_data[:enrollments_present?]))
              census_employee.build_hbx_enrollment_for_cobra
              census_employee.save!
              puts("Sucessfully created Cobra enrollment for person with hbx_id: #{employee_data['employee_hbx_id']}")
            else
              puts("Enrollment not generated for person #{employee_data['employee_hbx_id']} -- census_employee aasm_state: #{census_employee.aasm state}")
            end
          rescue StandardError => e
            puts("Enrollment not generated for person #{employee_data['employee_hbx_id']} due to #{e.message}")
          end
        else
          puts("No employee role record found for #{employee_data['employee_hbx_id']}")
        end
      else
        puts("No person record found for #{employee_data['employee_hbx_id']}")
      end
    end
  end
end

 hbx_ids = ['20081537', '20123739', '20003458', '19817282', '20066760', '19843745', '2512643', '20111622']

 hbx_ids.each do |hbx_id|
  person = Person.by_hbx_id(hbx_id)
  e_roles = person.employee_roles
  puts e_roles.count
  e_roles.each do |role|
    puts "#{role.census_employee.employer_profile.fei} - #{role.census_employee.aasm_state} -  #{role.census_employee&.employment_terminated_on} - #{role.census_employee&.coverage_terminated_on}"
  end
 end






