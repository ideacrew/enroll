require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeIncorrectTerminationDateInEnrollment < MongoidMigrationTask
  def migrate
    begin
      enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id'].to_s).first
      new_termination_date = ENV['termination_date']
      if enrollment.nil?
        puts "No enrollment with given hbx_id was found"
      elsif enrollment.aasm_state != "terminated"
        puts "The enrollment is not in terminated state"
      else
        enrollment.update_attributes(terminated_on: new_termination_date)
        puts "Changed Enrollment effective on date to #{new_termination_date}" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end
