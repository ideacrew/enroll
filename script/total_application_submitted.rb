def total_families(families, file_name, offset_count)
  field_names = ["PrimaryHbxID", "PrimaryFullName"]
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    families.no_timeout.limit(10_000).offset(offset_count).inject([]) do |_dummy, family|
      primary = family.primary_person
      csv << [primary.hbx_id, primary.full_name]
      rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end
​
families = Family.all
total_families_count = families.count
families_per_iteration = 10_000.0
number_of_iterations = (total_families_count / families_per_iteration).ceil
counter = 0
​
while counter < number_of_iterations
  file_name = "#{Rails.root}/number_of_submitted_applications_ie_total_families_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = families_per_iteration * counter
  total_families(families, file_name, offset_count)
  counter += 1
end

puts "Number of Submitted Applications (gross). Total number of families in the system are: #{total_families_count}"