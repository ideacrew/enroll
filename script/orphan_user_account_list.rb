  require 'csv'
  field_names  = %w(
                     user_name
                     email  
                     )
  processed_count = 0
  file_name = "#{Rails.root}/orphan_user_report_#{TimeKeeper.date_of_record.strftime("%m_%d_%Y")}.csv"
  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << field_names
    User.orphans.each do |user|
        csv << [
          user.oim_id,
          user.email
        ]
      processed_count += 1
    end
    offset = offset + batch_size
    puts "#{processed_count} orphan user listed in #{file_name}" unless Rails.env.test?
  end
