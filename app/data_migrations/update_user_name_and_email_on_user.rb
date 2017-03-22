require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateUserNameAndEmailOnUser < MongoidMigrationTask
  def migrate
    begin
      action = ENV['action'].to_s
      email = ENV['user_email'].to_s
      user_name = ENV['user_name'].to_s
      headless_user = ENV['headless_user'].to_s
      find_user_by = ENV['find_user_by']
      record = (find_user_by.casecmp("email") == 0) ? find_user_from_email(email) : find_user_by_user_name(user_name) 
      if record.size != 1
        puts "No user record (or) found more than 1 user record with e-mail/username you entered" unless Rails.env.test?
        return
      end

      if action.blank? && headless_user.casecmp("yes") != 0
        puts "Please give input. Check your query" unless Rails.env.test?
        return
      end

      if action.casecmp("update_username") == 0
        update_oim_id(record.first, user_name)
      end

      if action.casecmp("update_email") == 0
        update_email(record.first, email)
      end

      if headless_user.casecmp("yes") == 0
        handle_headless_user(record.first)
      end

    rescue => e
      puts "#{e}"
    end
  end

  def find_user_from_email(email)
    User.where(email: email)
  end

  def find_user_by_user_name(user_name)
    User.where(oim_id: user_name)
  end

  def update_oim_id(user, user_name)
    user.update_attributes!(oim_id: user_name)
    puts "Succesfully updated username" unless Rails.env.test?
  end

  def update_email(user, email)
    user.update_attributes!(email: email)
    puts "Succesfully updated email" unless Rails.env.test?
  end

  def handle_headless_user(user)
    if user.person.blank?
      user.destroy!
      puts "Succesfully destroyed headless user record" unless Rails.env.test?
    else
      puts "This is not a headless user" unless Rails.env.test?
    end
  end
end
