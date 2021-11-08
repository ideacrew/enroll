def process_users(families, file_name, offset_count)
  field_names = ["PrimaryHbxID", "PersonFullName", "HasStaffRole?"]
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    families.no_timeout.limit(10_000).offset(offset_count).inject([]) do |_dummy, family|
      person = family&.primary_person
      if person.present? && person.user.present?
        csv << [person.hbx_id, person.full_name, person.hbx_staff_role.present?]
        @total_families_counter += 1
      end
    rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end

prev_day = TimeKeeper.date_of_record.yesterday
@state_at = prev_day.beginning_of_day
@end_at = prev_day.end_of_day
families = Family.all.where(:created_at => { "$gte" => start_at, "$lte" => end_at }, external_app_id: nil)
total_count = families.count
families_per_iteration = 10_000.0
number_of_iterations = (total_count / families_per_iteration).ceil
counter = 0
@total_families_counter = 0

while counter < number_of_iterations
  file_name = "#{Rails.root}/user_accounts_with_no_external_id_created_yesterday_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = families_per_iteration * counter
  process_families(families, file_name, offset_count)
  counter += 1
end

puts "6.1B Number of new Accounts created on a single day(No external app id). Total number of New accounts created yesterday: #{@total_families_counter}"