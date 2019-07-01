  require 'csv'
  field_names  = %w(
                     first_name
                     last_name
                     hbx_id
                     user_name
                     email  
                     )
  processed_count = 0
  file_name = "#{Rails.root}/orphan_user_report_#{TimeKeeper.date_of_record.strftime("%m_%d_%Y")}.csv"
  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << field_names
    User.orphans.each do |user|
      if user.person.nil?
        csv << [
          "No Person Linked",
          "No Person Linked",
          "No Person Linked",
          user.oim_id,
          user.email
        ]
      else
        csv << [
          user.person.first_name,
          user.person.last_name,
          user.person.hbx_id,
          user.oim_id,
          user.email
        ]
        processed_count += 1
      end
    end
    puts "#{processed_count} orphan user listed in #{file_name}" unless Rails.env.test?
  end
