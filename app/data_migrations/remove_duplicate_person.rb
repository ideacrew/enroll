require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveDuplicatePerson < MongoidMigrationTask
  def migrate
    begin
      ssn = ENV['ssn']
      dob = ENV['dob']
      first_name = ENV['first_name']
      last_name = ENV['last_name']
      return "Invalid Details , enter ssn, dob , first_name and last_name" if ssn.blank? || dob.blank? || first_name.blank? || last_name.blank?
      people = Person.match_by_id_info(
          ssn: ssn,
          dob: dob,
          last_name: last_name,
          first_name: first_name
      )

      if people.count > 1
        invalid_person = people.select { |p| p.ssn.nil?}
        invalid_person.each do |person|
          puts "Removing Person with details #{person.inspect}"
          person.update_attribute("is_active",false)
        end
      else
        puts "No invalid person to remove"
      end

    rescue => e
      puts "#{e}"
    end
  end
end