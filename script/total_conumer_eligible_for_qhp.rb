def process_ivl_families_with_qhp(families, file_name, offset_count)
  field_names = ["PrimaryHbxID", "PrimaryFullName", "MemberHbxID", "MemberFullName", "MemberIncarcerated", "MemberApplyingForCoverage", "MemberHasInStateAddress", "MemberMedicaidEligible", "MemberCitzenStatus"]
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    families.no_timeout.limit(10_000).offset(offset_count).inject([]) do |_dummy, family|
      primary = family.primary_person
      thh = family.latest_household.latest_active_tax_household_with_year(2022)
      family.family_members.where(is_active: true).each do |f_member|
        in_state_address = f_member.person.addresses.where(state: "ME").present?
        medicaid_eligible =
            if thh.present?
              thh.tax_household_members.where(applicant_id: f_member.id).first&.is_medicaid_chip_eligible
            else
              false
            end
        member_citizen_status = f_member.person&.citizen_status
        if !f_member&.is_incarcerated && f_member.is_applying_coverage && in_state_address && ["us_citizen", "alien_lawfully_present", "naturalized_citizen"].include?(member_citizen_status) && !medicaid_eligible
        csv << [primary.hbx_id, primary.full_name, f_member.hbx_id, f_member.full_name, f_member.is_incarcerated, f_member.is_applying_coverage, in_state_address, medicaid_eligible, member_citizen_status]
        @total_member_counter_with_qhp += 1
        end
      end
      rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end
​
valid_people = Person.where(:is_incarcerated.ne => true, :"consumer_role.is_applying_coverage" => true, :"addresses.state" => "ME", :"consumer_role.lawful_presence_determination.citizen_status".in => ["us_citizen", "alien_lawfully_present", "naturalized_citizen"])
families = Family.where(:'family_members.person_id'.in => valid_people.pluck(:id))
total_count = families.count
families_per_iteration = 10_000.0
number_of_iterations = (total_count / families_per_iteration).ceil
counter = 0
@total_member_counter_with_qhp = 0
​
while counter < number_of_iterations
  file_name = "#{Rails.root}/consumers_eligible_for_qhp_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = families_per_iteration * counter
  process_ivl_families_with_qhp(families, file_name, offset_count)
  counter += 1
  puts "Counter: #{counter}, TotalMemberCounter: #{@total_member_counter_with_qhp}"
end
puts "Consumers Eligible for QHP (gross). Total number of family members that eligible for QHP are: #{@total_member_counter_with_qhp}"
