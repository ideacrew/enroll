require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeGender < MongoidMigrationTask
  def migrate
    begin
      hbx_id = (ENV['hbx_id']).to_s
      id = (ENV['ce_id']).to_s
      person_gender = (ENV['gender']).to_s
      Person.where(hbx_id: hbx_id).first.update_attribute(:gender, person_gender)
      if id.present?
        ce = CensusEmployee.where(id: id).first
        unless ce.nil?
          ce.update_attribute(:gender, person_gender)
          puts "Changed Gender of an census employee with id: #{ENV['id']} to #{person_gender}" unless Rails.env.test?
        else
          puts "No census employee was found with id: #{ENV['id']}" unless Rails.env.test?
        end
      end
      puts "Changed Gender of a Person with hbx_id: #{ENV['hbx_id']} to #{person_gender}" unless Rails.env.test?
    rescue
      puts "Bad Person Record" unless Rails.env.test?
    end
  end
end