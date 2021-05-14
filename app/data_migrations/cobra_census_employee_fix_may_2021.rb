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
          cobra_date = employee_data[:cobra_start_date]&.to_date
          begin
            census_employee.update_for_cobra(cobra_date, nil)
            puts("Sucessfully created Cobra enrollment for person with hbx_id: #{employee_data['employee_hbx_id']}")
          rescue StandardError => e
            e.message
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
