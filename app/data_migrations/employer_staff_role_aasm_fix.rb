require File.join(Rails.root, "lib/mongoid_migration_task")

class EmployerStaffRoleAasmFix < MongoidMigrationTask

  def migrate
    Person.where("employer_staff_roles": { "$exists": true, "$not": {"$size": 0}},
                 "employer_staff_roles.aasm_state": { "$exists": false }).each do |person|
      begin
        person.employer_staff_roles.each do |esr|
          esr.update_attributes!({:aasm_state => employer_staff_role_aasm_state(esr)})
        end
      rescue Exception => e
        puts "Error: person #{person.hbx_id} #{e.message}" unless Rails.env.test?
      end
    end
  end

  def employer_staff_role_aasm_state(employer_staff_role)
    if employer_staff_role.is_active
      'is_active'
    else
      'is_closed'
    end
  end
end
