require File.join(Rails.root, 'lib/mongoid_migration_task')

class MoveEmployerStaffRoleBetweenTwoPeople < MongoidMigrationTask
  def migrate
    trigger_single_table_inheritance_auto_load_of_child = VlpDocument
    begin
      from_hbx_id = ENV['from_hbx_id']
      to_hbx_id = ENV['to_hbx_id']
      from_person = Person.where(hbx_id:from_hbx_id).first
      to_person = Person.where(hbx_id:to_hbx_id).first

      if from_person.nil?
        puts "No person was found by the given hbx_id: #{from_hbx_id}" unless Rails.env.test?
        return
      elsif to_person.nil?
        puts  "No person was found by the given hbx_id: #{to_hbx_id}" unless Rails.env.test?
        return
      end

      from_person.employer_staff_roles.each do |role|
        begin
          emp_staff_role = EmployerStaffRole.new(is_owner: role.is_owner,
            is_active: role.is_active, aasm_state: role.aasm_state,
            employer_profile_id: role.employer_profile_id,
            benefit_sponsor_employer_profile_id: role.benefit_sponsor_employer_profile_id)
          to_person.employer_staff_roles << emp_staff_role
          role.close_role!
          role.update_attributes!(is_active: false)
          from_person.save!
          to_person.save!
        rescue Exception => error
          puts "Could not process role with id: #{role.id.to_s},
          for the person with hbx_id: #{from_person.hbx_id}, Error: #{error.message}" unless Rails.env.test?
        end
      end

      puts "transfer employer staff roles from hbx_id: #{from_hbx_id}
      to hbx_id: #{to_hbx_id}" unless Rails.env.test?
    rescue Exception => e
      puts "#{e.message}" unless Rails.env.test?
    end
  end
end
