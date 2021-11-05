def process_people(people, file_name, offset_count)
  field_names = ["PrimaryHbxID", "PersonFullName", "ApplyingForCoverage?"]
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    people.no_timeout.limit(10_000).offset(offset_count).inject([]) do |_dummy, person|
      csv << [person.hbx_id, person.full_name, person&.consumer_role&.is_applying_coverage]
      @total_member_counter_for_coverage += 1
      rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end
​
people = Person.all.where(:"consumer_role.is_applying_coverage" => true)
total_count = people.count
people_per_iteration = 10_000.0
number_of_iterations = (total_count / people_per_iteration).ceil
counter = 0
@total_member_counter_for_coverage = 0
​
while counter < number_of_iterations
  file_name = "#{Rails.root}/consumers_on_applications_submitted_ie_people_applying_for_coverage_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = people_per_iteration * counter
  process_people(people, file_name, offset_count)
  counter += 1
end
​
puts "7. Consumers on Applications Submitted (gross). Count of people that are applying for coverage: #{@total_member_counter_for_coverage}"
