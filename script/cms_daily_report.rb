# Total Enrolled Member count
member_count = HbxEnrollment.collection.aggregate([
  {"$match" => {
      "hbx_enrollment_members" => {"$ne" => nil},
      "external_enrollment" => {"$ne" => true},
      "coverage_kind" => "health",
      "consumer_role_id" => {"$ne" => nil},
      "product_id" => { "$ne" => nil},
      "aasm_state" => {"$in" =>  HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES},
      "effective_on" => {"$gte" => Date.new(2022,1,1)}
  }
  },
  {"$project" => {"member_count" => {"$size" => "$hbx_enrollment_members"}}},
  {"$group" => {"_id" => 1, "total_members" => {"$sum" => "$member_count"}}}
])
​total_member_enrolled = member_count.first['total_members']

# New Consumers Enrolled
new_enrolled_members = 0
qs = Queries::PolicyAggregationPipeline.new
qs.filter_to_individual.health.filter_to_active.with_effective_date({"$gt" => Date.new(2021,12,31)}).eliminate_family_duplicates
qs.add({ "$match" => {"policy_purchased_at" => {"$gt" => Time.mktime(2021,11,1,0,0,0)}}})
qs.add("$sort" => {"policy_purchased_at" => 1})
qs.evaluate.each do |enrollment|
  enrollment["hbx_enrollment_members"].each do |member|
    unless HbxEnrollment.where(
        :"hbx_enrollment_members.applicant_id" => member["applicant_id"],
         "effective_on" => {"$lt" => Date.new(2022,1,1)},
         "family_id" => enrollment["_id"]["family_id"],
         "coverage_kind" => "health",
         "consumer_role_id" => {"$ne" => nil},
         "aasm_state" => {"$in" => HbxEnrollment::ENROLLED_STATUSES}).any?
      new_enrolled_members += 1
    end
  end
end
​
# Total Re-Enrollees
members = HbxEnrollment.collection.aggregate([
  {"$match" => {
     "hbx_enrollment_members" => {"$ne" => nil},
     "external_enrollment" => {"$ne" => true},
     "coverage_kind" => "health",
     "consumer_role_id" => {"$ne" => nil},
     "product_id" => { "$ne" => nil},
     "aasm_state" => {"$in" =>  HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES},
     "effective_on" => {"$gte" => Date.new(2022,1,1)},
  }},
  {"$unwind" => "$hbx_enrollment_members"},
  {"$project" => {"applicant_id" => "$hbx_enrollment_members.applicant_id",
                 "aasm_state" => "$aasm_state",
                 "family_id" => "$family_id",
                 "hbx_id" => "$hbx_id",
                 "purchased_at" => { "$ifNull" => ["$created_at", "$submitted_at"] }}
   }
])
​
total_re_enrolles = 0
members.each do |member|
  if member["aasm_state"] == "auto_renewing"
    total_re_enrolles += 1
  elsif HbxEnrollment.where(:"hbx_enrollment_members.applicant_id" => member["applicant_id"],
                            "effective_on" => {"$lt" => Date.new(2022,1,1)},
                            "coverage_kind" => "health",
                            "family_id" => member["family_id"],
                            "consumer_role_id" => {"$ne" => nil},
                            "aasm_state" => {"$in" => HbxEnrollment::ENROLLED_STATUSES}).any?
    total_re_enrolles += 1
  end
end
​
# Total active enrollees
total_active_re_enrolles = 0
members.each do |member|
  if member["purchased_at"] >= Date.new(2021,11,1).beginning_of_day && member["aasm_state"] != "auto_renewing" &&
      HbxEnrollment.where(:"hbx_enrollment_members.applicant_id" => member["applicant_id"],
                          "effective_on" => {"$lt" => Date.new(2022,1,1)},
                          "coverage_kind" => "health",
                          "family_id" => member["family_id"],
                          "consumer_role_id" => {"$ne" => nil},
                          "aasm_state" => {"$in" => HbxEnrollment::ENROLLED_STATUSES}).any?
    total_active_re_enrolles += 1
  end
end
​
# Total auto enrollees
total_auto_re_enrolles = 0
members.each do |member|
  if member["aasm_state"] == "auto_renewing"
    total_auto_re_enrolles += 1
  elsif member["purchased_at"] <= Date.new(2021,11,1).beginning_of_day &&
      HbxEnrollment.where(:"hbx_enrollment_members.applicant_id" => member["applicant_id"],
                          "effective_on" => {"$lt" => Date.new(2022,1,1)},
                          "coverage_kind" => "health",
                          "family_id" => member["family_id"],
                          "consumer_role_id" => {"$ne" => nil},
                          "aasm_state" => {"$in" => HbxEnrollment::ENROLLED_STATUSES}).any?
    total_auto_re_enrolles += 1
  end
end

puts "Total Member Enrolled(2022) Count: #{member_count.first['total_members']}"
puts "Total New Member/Consumer selected 2022 enrollments after 11/1/2021 : #{new_enrolled_members}"
puts "Total Re-Enrolled(2022) Member: #{total_re_enrolles}"
puts "Total Active Renewed(2022) Member: #{total_active_re_enrolles}"
puts "Total Auto Renewed(2022) Member: #{total_auto_re_enrolles}"


families = Family.all
total_families_count = families.count

prev_day = TimeKeeper.date_of_record.yesterday
start_at = prev_day.beginning_of_day
end_at = prev_day.end_of_day
users = User.all.where(:created_at => { "$gte" => start_at, "$lte" => end_at })
total_user_count = users.count
users_per_iteration = 10_000.0
number_of_iterations = (total_user_count / users_per_iteration).ceil
counter = 0
total_user_counter = 0

while counter < number_of_iterations
  offset_count = users_per_iteration * counter
  users.no_timeout.limit(10_000).offset(offset_count).each do |user|
    person = user.person
    if person.present? && person.consumer_role.present?
      total_user_counter += 1
    end
  end
  counter += 1
end

prev_day = TimeKeeper.date_of_record.yesterday
start_at = prev_day.beginning_of_day
end_at = prev_day.end_of_day
total_family_or_iap_submitted_count = 0

families = Family.all.where(:created_at => { "$gte" => start_at, "$lte" => end_at })
families_per_iteration = 10_000.0
number_of_iterations = (families.count / families_per_iteration).ceil
counter = 0

while counter < number_of_iterations
  offset_count = families_per_iteration * counter
  families.no_timeout.limit(10_000).offset(offset_count) do |family|
    fa_apps = ::FinancialAssistance::Application.where(family_id: family.id)
    total_family_or_iap_submitted_count += 1 if fa_apps.blank?
  end
  counter += 1
end

applications = FinancialAssistance::Application.where(:submitted_at => { "$gte" => start_at, "$lte" => end_at })
total_family_or_iap_submitted_count += applications.count

people_applying_for_coverage = Person.all.where(:"consumer_role.is_applying_coverage" => true).count

families = Family.where(:"households.tax_households" => { "$elemMatch" => { :"effective_ending_on" => nil, :"effective_starting_on".gte => Date.new(2022) } })
total_count = families.count
families_per_iteration = 10_000.0
number_of_iterations = (total_count / families_per_iteration).ceil
counter = 0
total_member_eligible_medicaid_or_chip = 0

while counter < number_of_iterations
  offset_count = families_per_iteration * counter
  families.no_timeout.limit(10_000).offset(offset_count) do |family|
    primary = family.primary_person
    thh = family.latest_household.tax_households.where(effective_ending_on: nil, :"effective_starting_on".gte => Date.new(2022)).first
    next unless thh.present?
    thhm_medicaid_members = thh.tax_household_members.where(is_medicaid_chip_eligible: true)
    total_member_eligible_medicaid_or_chip += thhm_medicaid_members.count
  end
  counter += 1
end

valid_people = Person.where(:is_incarcerated.ne => true, :"consumer_role.is_applying_coverage" => true, :"addresses.state" => "ME", :"consumer_role.lawful_presence_determination.citizen_status".in => ["us_citizen", "alien_lawfully_present", "naturalized_citizen"])
families = Family.where(:'family_members.person_id'.in => valid_people.pluck(:id))
total_count = families.count
families_per_iteration = 10_000.0
number_of_iterations = (total_count / families_per_iteration).ceil
counter = 0
total_member_eligible_for_qhp = 0
while counter < number_of_iterations
  offset_count = families_per_iteration * counter
  families.no_timeout.limit(10_000).offset(offset_count) do |family|
    thh = family.latest_household.latest_active_tax_household_with_year(2022)
    next unless thh.present?
    family.family_members.active.each do |f_member|
      next if f_member.is_incarcerated
      next unless f_member.is_applying_coverage
      member_citizen_status = f_member.person&.citizen_status
      next unless ["us_citizen", "alien_lawfully_present", "naturalized_citizen"].include?(member_citizen_status)
      in_state_address = f_member.person.addresses.where(state: "ME").present?
      next unless in_state_address
      medicaid_eligible = thh.tax_household_members.where(applicant_id: f_member.id).first&.is_medicaid_chip_eligible
      next unless medicaid_eligible
      total_member_eligible_for_qhp += 1
    end
  end
  counter += 1
end

families = Family.where(:"households.tax_households" => { "$elemMatch" => { :"effective_ending_on" => nil, :"effective_starting_on".gte => Date.new(2022) } })
total_count = families.count
limit = 10_000.0
number_of_iterations = (total_count / limit).ceil
counter = 0
total_is_ia_eligible_member = 0
while counter < number_of_iterations
  offset_count = families_per_iteration * counter
  families.no_timeout.limit(limit).offset(offset_count).each do |family|
    thh = family.latest_household.tax_households.where(effective_ending_on: nil, :"effective_starting_on".gte => Date.new(2022)).first
    total_is_ia_eligible_member += thh.tax_household_members.where(is_ia_eligible: true).count if thh.present?
  end
  counter += 1
end

puts "Number of Submitted Applications (gross). Total number of families in the system are: #{total_families_count}"
puts "Number of Accounts created on a single day(Accounts Created). Total number of Users created yesterday: #{total_user_counter}"
puts "Applications Submitted, the combined total number of families created yesterday and number of applications submitted yesterday: #{total_family_or_iap_submitted_count}"
puts "Consumers on Applications Submitted (gross). Count of people that are applying for coverage: #{people_applying_for_coverage}"
puts "Consumers Determined Eligible for Medicaid/CHIP (gross). Total number of family members that are found eligible for MedicAid or CHIP are: #{total_member_eligible_medicaid_or_chip}"
puts "Consumers Eligible for QHP (gross). Total number of family members that eligible for QHP are: #{total_member_eligible_for_qhp}"
puts "Consumers Eligible for QHP, with Financial Assistance (gross). Total number of family members that are found eligible for APTC(insurance_assistance) are: #{total_is_ia_eligible_member}"

CSV.open("#{Rails.root}/CMS_daily_report_summary.csv", "w", force_quotes: true) do |csv|
  data =[
      ["","",""],
      ["","CMS Reporting Summary",""],
      ["","",""],
      ["","Total Plan Selections (net)", total_member_enrolled],
      ["","New Consumers (net)", new_enrolled_members],
      ["","Total Re-enrollees (net)", total_re_enrolles],
      ["","Active Re-enrollees (net)", total_active_re_enrolles],
      ["","Automatic Re-enrollees (net)", total_auto_re_enrolles],
      ["","Number of Submitted Applications (gross)", total_families_count],
      ["","Number of Accounts created on a single day(Accounts Created)", total_user_counter],
      ["","Applications Submitted", total_family_or_iap_submitted_count],
      ["","Consumers on Applications Submitted (gross)", people_applying_for_coverage],
      ["","Consumers Determined Eligible for Medicaid/CHIP (gross)", total_member_eligible_medicaid_or_chip],
      ["","Consumers Eligible for QHP (gross)", total_member_eligible_for_qhp],
      ["","Consumers Eligible for QHP, with Financial Assistance (gross)", total_is_ia_eligible_member]
  ]
  data.each do |da|
    csv << da
  end
end