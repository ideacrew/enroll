  require 'csv'
  
  batch_size = 500
  offset = 0
  user_count = User.count

  file_name = "#{Rails.root}/ea_access_list_#{DateTime.now.strftime("%m_%d_%Y_%H_%M")}.csv"

  processed_count = 0
  
  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << ["User Id", "User's Name", "OIM ID", "Email" ,"Roles", "Created Date", "Last Login Date"]
    while offset < user_count
      User.offset(offset).limit(batch_size).each do |user|
        if processed_count % 1000 == 0
          puts "processed #{processed_count}" unless Rails.env.test?
        end
        begin
          person = user.person
          if person.nil?
            csv << ["No person record found", "No person record", user.oim_id, user.email, user.roles, user.created_at, user.last_sign_in_at]
          else
            csv << [user.person.hbx_id, user.person.full_name, user.oim_id, user.email, user.roles, user.created_at, user.last_sign_in_at]
          end
        rescue Exception => e
          puts "Errors #{e} #{e.backtrace}"
        end
        processed_count += 1
      end
      offset = offset + batch_size
    end
    puts "#{processed_count} users to output file: #{file_name}" unless Rails.env.test?
  end