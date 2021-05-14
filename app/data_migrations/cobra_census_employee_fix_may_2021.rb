# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# A class to fix missing cobra enrollments
class FixPlanYear < CobraCensusEmployeeFixMay2021
  def migrate
    ivl_csv = File.read(ENV['census_employee_csv_file_location'])
    CSV.parse(ivl_csv, :headers => true).each do |employee_data|
      employee_data = employee_data.to_h.with_indifferent_access
      person = Person.where(hbx_id: employee_data['employee_hbx_id']).first
      puts("No person record found for #{employee_data['employee_hbx_id']}") if person.blank?
      employee_role = person.employee_roles.detect { |er| er.employer_profile.hbx_id == employee_data[:employer_hbx_id] }
      puts("No employee role record found for #{employee_data['employee_hbx_id']}") if employee_role.blank?
      census_employee = employee_role.census_employee
      puts("Census employee found for #{employee_data['employee_hbx_id']}, beginning cobra enrollment.")
      cobra_date = employee_data[:cobra_start_date]&.to_date
      census_employee.update_for_cobra(cobra_date, nil)
    end
  end
end
