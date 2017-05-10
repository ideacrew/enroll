require File.join(Rails.root, "lib/mongoid_migration_task")

class TerminateEnrWithDate < MongoidMigrationTask
  def migrate
    begin
      person_hbx_id = (ENV['person_hbx_id']).to_s
      enr_hbx_id = (ENV['enr_hbx_id']).to_s
      terminated_on = Date.strptime(ENV['terminated_on'].to_s, "%m/%d/%Y")

      enr = Person.where(hbx_id: person_hbx_id).first.primary_family.active_household.hbx_enrollments.where(hbx_id: enr_hbx_id).first
      enr.terminate_coverage!(terminated_on) if enr.effective_on < terminated_on

      puts "Terminated the enrollment with hbx_id: #{enr_hbx_id}, for the given person with hbx_id: #{person_hbx_id}, Status of Enrollment: #{enr.aasm_state} with termination date: #{enr.terminated_on} " unless Rails.env.test?
    rescue
      puts "Bad Person Record with hbx_id: #{person_hbx_id}" unless Rails.env.test?
    end
  end
end
