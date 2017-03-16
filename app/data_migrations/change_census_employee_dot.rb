require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeCensusEmployeeDot < MongoidMigrationTask
  def migrate
    begin
      ce=CensusEmployee.by_ssn(ENV['ssn']).first
      dot = ENV['date_of_terminate']
      if ce.nil?
        puts "No census employee was found with the given ssn"
      elsif ce.aasm_state != "employment_terminated"
        puts "The dot can not be set as the census employee is not in employment terminated state"
      else
        ce.update_attributes(employment_terminated_on: dot)
        puts "Changed census employee employment termination date to #{dot}" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end