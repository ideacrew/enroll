require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeGeneralAgencyStaffRole < MongoidMigrationTask
  def migrate
    incorrect_person_hbx_id = ENV['incorrect_person_hbx_id']
    correct_person_hbx_id = ENV['correct_person_hbx_id']
    incorrect_person = Person.where(hbx_id:incorrect_person_hbx_id).general_agency_staff_roles.first
    if incorrect_person.nil?
      puts "No person was found with given hbx_id" unless Rails.env.test?
    else
      correct_person = Person.where(hbx_id:correct_person_hbx_id).first
      correct_person.general_agency_staff_roles << GeneralAgencyStaffRole.new(
                        npn: ga.npn,
                        general_agency_profile_id: ga.general_agency_profile_id,
                        aasm_state: ga.aasm_state )
      correct_person.save!
      puts "Correct Person is Assigned the GA Staff Role" unless Rails.env.test?

      incorrect_person.general_agency_staff_roles[0].destroy!
      incorrect_person.save!
      puts "Incorrect Person is Removed the GA Staff Role" unless Rails.env.test?
    end
  end
end
