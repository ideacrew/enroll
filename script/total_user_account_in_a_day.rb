def process_users(users, file_name, offset_count)
  field_names = ["PrimaryHbxID", "PersonFullName", "HasStaffRole?"]
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    users.no_timeout.limit(10_000).offset(offset_count).inject([]) do |_dummy, user|
      person = user&.person
      if person.present? && person.hbx_staff_role.blank?
        csv << [person.hbx_id, person.full_name, person.hbx_staff_role.present?]
        @total_user_counter += 1
      end
      rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end

prev_day = TimeKeeper.date_of_record.yesterday
@state_at = prev_day.beginning_of_day
@end_at = prev_day.end_of_day
users = User.all.where(:created_at => { "$gte" => @state_at, "$lte" => @end_at })
total_user_count = users.count
users_per_iteration = 10_000.0
number_of_iterations = (total_user_count / users_per_iteration).ceil
counter = 0
@total_user_counter = 0
​
while counter < number_of_iterations
  file_name = "#{Rails.root}/number_of_user_accounts_created_yesterday_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = users_per_iteration * counter
  process_users(users, file_name, offset_count)
  counter += 1
end
​
puts "Number of Accounts created on a single day(Accounts Created). Total number of Users created yesterday: #{@total_user_counter}"
