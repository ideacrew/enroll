prev_day = TimeKeeper.date_of_record.yesterday
@state_at = prev_day.beginning_of_day
@end_at = prev_day.end_of_day
@total_submitted_count = 0
​
def process_families(families, file_name, offset_count)
  field_names = ["PrimaryHbxID", "PersonFullName", "FamilyCreatedAt", "NumberOfFAApplications"]
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    families.no_timeout.limit(10_000).offset(offset_count).inject([]) do |_dummy, family|
      fa_apps = ::FinancialAssistance::Application.where(family_id: family.id)
      if fa_apps.blank?
        primary = family&.primary_person
        csv << [primary.hbx_id, primary.full_name, family.created_at.to_s, fa_apps.count]
        @total_submitted_count += 1
      end
      rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end
​
families = Family.all.where(:created_at => { "$gte" => @state_at, "$lte" => @end_at })
families_per_iteration = 10_000.0
number_of_iterations = (families.count / families_per_iteration).ceil
counter = 0
​
while counter < number_of_iterations
  file_name = "#{Rails.root}/applications_submitted_ie_number_of_families_created_yesterday_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = families_per_iteration * counter
  process_families(families, file_name, offset_count)
  counter += 1
end
​
def process_applications(applications, file_name, offset_count)
  field_names = ["PrimaryHbxID", "PersonFullName", "ApplicationSubmittedAt", "ApplicationHbxID", "ApplicationAasmState"]
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    applications.no_timeout.limit(10_000).offset(offset_count).inject([]) do |_dummy, application|
      primary = application.family.primary_person
      csv << [primary.hbx_id, primary.full_name, application.submitted_at.to_s, application.hbx_id, application.aasm_state]
      @total_submitted_count += 1
      rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end
​
applications = FinancialAssistance::Application.where(:submitted_at => { "$gte" => @state_at, "$lte" => @end_at })
applications_per_iteration = 10_000.0
number_of_iterations = (applications.count / applications_per_iteration).ceil
counter = 0
​
while counter < number_of_iterations
  file_name = "#{Rails.root}/applications_submitted_ie_number_of_applications_submitted_yesterday_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = applications_per_iteration * counter
  process_applications(applications, file_name, offset_count)
  counter += 1
end
​
puts "Applications Submitted, the combined total number of families created yesterday and number of applications submitted yesterday: #{@total_submitted_count}"
