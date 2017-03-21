require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateUserNameAndEmailOnUser < MongoidMigrationTask
  def migrate
    begin
      action = ENV['action'].to_s
      email = ENV['user_email'].to_s
      user_name = ENV['user_name'].to_s
      headless_user = ENV['headless_user'].to_s
      find_user_by = ENV['find_user_by']
      record = find_user_by == /email/i ? find_user_from_email(email) : find_user_by_user_name(user_name)

      if record.size != 1
        puts "No user record (or) found more than 1 user record with e-mail/username you entered"
        return
      end

      if action == /update_username/i
        update_oim_id(record.first, user_name)
      end

      if action == /update_email/i
        update_email(record.first, email)
      end

      if headless_user == /yes/i
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
    puts "Succesfully updated username"
  end

  def update_email(user, email)
    user.update_attributes!(email: email)
    puts "Succesfully updated email"
  end

  def handle_headless_user(user)
    if user.person.blank?
      user.destroy!
      puts "Succesfully destroyed headless user record"
    else
      puts "This is not a headless user"
    end
  end
end
