require File.join(Rails.root, "lib/mongoid_migration_task")
class LinkUserAndPerson< MongoidMigrationTask
  def migrate
    hbx_id = ENV['person_hbx_id']
    user_id = ENV['user_id']
    person = Person.where(hbx_id:hbx_id)
    user=User.find(user_id)
    if person.size != 1
      puts "No person or more than one person was found by the given hbx_id: #{hbx_id}" unless Rails.env.test?
      return
    end

    if user.nil?
      puts "No user was found with give id: #{user_id} " unless Rails.env.test?
    end

    person.first.update_attributes(user_id:user.id)
    if person.first.user.nil?
      puts "The person with hbx_id #{hbx_id} has been linked to user with id #{user_id}" unless Rails.env.test?
    else    
      puts  "The person with hbx_id #{hbx_id} has been delinked from the previous user and relinked to user with id #{user_id}" unless Rails.env.test?
    end
  end
end