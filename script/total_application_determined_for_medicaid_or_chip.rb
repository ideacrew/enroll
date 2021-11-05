def process_ivl_families_medicaid_or_chip(families, file_name, offset_count)
  field_names = ["PrimaryHbxID", "PrimaryFullName", "MedicaidMemberFullName", "IsMedicaidChipEligible"]
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    families.no_timeout.limit(10_000).offset(offset_count).inject([]) do |_dummy, family|
      primary = family.primary_person
      thh = family.latest_household.tax_households.where(effective_ending_on: nil, :"effective_starting_on".gte => Date.new(2022)).first
      thhm_medicaid_members = thh&.tax_household_members.where(is_medicaid_chip_eligible: true)
      if thh.present? && thhm_medicaid_members.present?
        thhm_medicaid_members = thh.tax_household_members.where(is_medicaid_chip_eligible: true)
        if thhm_medicaid_members.present?
          thhm_medicaid_members.each do |medicaid_thhm|
            csv << [primary.hbx_id, primary.full_name, medicaid_thhm&.person&.full_name, medicaid_thhm&.is_medicaid_chip_eligible]
          end
        end
        @total_member_counter_medicaid_or_chip += thhm_medicaid_members.count
      end
      rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end
​
families = Family.where(:"households.tax_households" => { "$elemMatch" => { :"effective_ending_on" => nil, :"effective_starting_on".gte => Date.new(2022) } })
total_count = families.count
families_per_iteration = 10_000.0
number_of_iterations = (total_count / families_per_iteration).ceil
counter = 0
@total_member_counter_medicaid_or_chip = 0
​
while counter < number_of_iterations
  file_name = "#{Rails.root}/consumers_determined_eligible_for_medicaid_or_chip_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = families_per_iteration * counter
  process_ivl_families_medicaid_or_chip(families, file_name, offset_count)
  counter += 1
  puts "Counter: #{counter}, TotalMemberCounter: #{@total_member_counter_medicaid_or_chip}"
end
puts "Consumers Determined Eligible for Medicaid/CHIP (gross). Total number of family members that are found eligible for MedicAid or CHIP are: #{@total_member_counter_medicaid_or_chip}"

