require "set"

all_enrolled_people = HbxEnrollment.collection.aggregate([
  {"$match" => {
      "hbx_enrollment_members" => {"$ne" => nil},
      "external_enrollment" => {"$ne" => true},
      "coverage_kind" => "health",
      "consumer_role_id" => {"$ne" => nil},
      "product_id" => { "$ne" => nil},
      "aasm_state" => {"$in" => HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES},
      "effective_on" => {"$gte" => Date.new(2022,1,1)}
  }
  },
  {"$project" => {"family_id" => "$family_id", "hbx_enrollment_members" => "$hbx_enrollment_members"}},
  {"$lookup" => {
    "from" => "families",
    "localField" => "family_id",
    "foreignField" => "_id",
    "as" => "family"
  }},
  {"$unwind" => "$family"},
  {"$unwind" => "$family.family_members"},
  {"$unwind" => "$hbx_enrollment_members"},
  {"$project" => {
      "family_id" => "$family_id",
      "person_id" => "$family.family_members.person_id",
      "applicant_id" => "$hbx_enrollment_members.applicant_id",
      "person_and_member_match" => {"$eq" => ["$family.family_members._id", "$hbx_enrollment_members.applicant_id"]},
    }
  },
  {"$match" => {"person_and_member_match" => true}},
  {"$project" => {"_id" => "$person_id", "total" => {"$sum" => 1}}}
])

all_people_ids = all_enrolled_people.map do |rec|
  rec["_id"]
end

all_enrolled_people_set = Set.new(all_people_ids)

pre_term_renewal_candidates = HbxEnrollment.collection.aggregate([
  {"$match" => {
      "hbx_enrollment_members" => {"$ne" => nil},
      "coverage_kind" => "health",
      "consumer_role_id" => {"$ne" => nil},
      "product_id" => { "$ne" => nil},
      "aasm_state" => {"$in" =>  HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES},
      "effective_on" => {"$lt" => Date.new(2022,1,1)}
  }
  },
  {"$project" => {"family_id" => "$family_id", "hbx_enrollment_members" => "$hbx_enrollment_members"}},
  {"$lookup" => {
    "from" => "families",
    "localField" => "family_id",
    "foreignField" => "_id",
    "as" => "family"
  }},
  {"$unwind" => "$family"},
  {"$unwind" => "$family.family_members"},
  {"$unwind" => "$hbx_enrollment_members"},
  {"$project" => {
      "family_id" => "$family_id",
      "person_id" => "$family.family_members.person_id",
      "applicant_id" => "$hbx_enrollment_members.applicant_id",
      "person_and_member_match" => {"$eq" => ["$family.family_members._id", "$hbx_enrollment_members.applicant_id"]},
    }
  },
  {"$match" => {"person_and_member_match" => true}},
  {"$project" => {"_id" => "$person_id", "total" => {"$sum" => 1}}}
])

pre_term_renewal_candidate_ids = pre_term_renewal_candidates.map do |rec|
  rec["_id"]
end

post_term_renewal_candidates = HbxEnrollment.collection.aggregate([
  {"$match" => {
      "hbx_enrollment_members" => {"$ne" => nil},
      "coverage_kind" => "health",
      "consumer_role_id" => {"$ne" => nil},
      "product_id" => { "$ne" => nil},
      "aasm_state" => {"$in" =>  ["coverage_expired"]},
      "effective_on" => {"$lt" => Date.new(2022,1,1)}
  }
  },
  {"$project" => {"family_id" => "$family_id", "hbx_enrollment_members" => "$hbx_enrollment_members"}},
  {"$lookup" => {
    "from" => "families",
    "localField" => "family_id",
    "foreignField" => "_id",
    "as" => "family"
  }},
  {"$unwind" => "$family"},
  {"$unwind" => "$family.family_members"},
  {"$unwind" => "$hbx_enrollment_members"},
  {"$project" => {
      "family_id" => "$family_id",
      "person_id" => "$family.family_members.person_id",
      "applicant_id" => "$hbx_enrollment_members.applicant_id",
      "person_and_member_match" => {"$eq" => ["$family.family_members._id", "$hbx_enrollment_members.applicant_id"]},
    }
  },
  {"$match" => {"person_and_member_match" => true}},
  {"$project" => {"_id" => "$person_id", "total" => {"$sum" => 1}}}
])

post_term_renewal_candidate_ids = post_term_renewal_candidates.map do |rec|
  rec["_id"]
end

pre_term_renewal_candidate_set = Set.new(pre_term_renewal_candidate_ids)
post_term_renewal_candidate_set = Set.new(post_term_renewal_candidate_ids)
renewal_candidate_set = pre_term_renewal_candidate_set | post_term_renewal_candidate_set

new_member_set = all_enrolled_people_set - renewal_candidate_set

re_enrolled_member_set = all_enrolled_people_set & renewal_candidate_set

pre_11_1_purchases = all_enrolled_people = HbxEnrollment.collection.aggregate([
  {"$match" => {
      "hbx_enrollment_members" => {"$ne" => nil},
      "external_enrollment" => {"$ne" => true},
      "coverage_kind" => "health",
      "consumer_role_id" => {"$ne" => nil},
      "product_id" => { "$ne" => nil},
      "created_at" => { "$lt" => TimeKeeper.start_of_exchange_day_from_utc(Date.new(2021,11,1))},
      "aasm_state" => {"$in" => HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES},
      "effective_on" => {"$gte" => Date.new(2022,1,1)}
  }
  },
  {"$project" => {"family_id" => "$family_id", "hbx_enrollment_members" => "$hbx_enrollment_members"}},
  {"$lookup" => {
    "from" => "families",
    "localField" => "family_id",
    "foreignField" => "_id",
    "as" => "family"
  }},
  {"$unwind" => "$family"},
  {"$unwind" => "$family.family_members"},
  {"$unwind" => "$hbx_enrollment_members"},
  {"$project" => {
      "family_id" => "$family_id",
      "person_id" => "$family.family_members.person_id",
      "applicant_id" => "$hbx_enrollment_members.applicant_id",
      "person_and_member_match" => {"$eq" => ["$family.family_members._id", "$hbx_enrollment_members.applicant_id"]},
    }
  },
  {"$match" => {"person_and_member_match" => true}},
  {"$project" => {"_id" => "$person_id", "total" => {"$sum" => 1}}}
])

pre_11_1_ids = pre_11_1_purchases.map do |rec|
  rec["_id"]
end

pre_11_1_purchase_set = Set.new(pre_11_1_ids)

post_11_1_purchases = all_enrolled_people = HbxEnrollment.collection.aggregate([
  {"$match" => {
      "hbx_enrollment_members" => {"$ne" => nil},
      "external_enrollment" => {"$ne" => true},
      "coverage_kind" => "health",
      "consumer_role_id" => {"$ne" => nil},
      "product_id" => { "$ne" => nil},
      "created_at" => { "$gte" => TimeKeeper.start_of_exchange_day_from_utc(Date.new(2021,11,1))},
      "aasm_state" => {"$in" => HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES},
      "effective_on" => {"$gte" => Date.new(2022,1,1)}
  }
  },
  {"$project" => {"family_id" => "$family_id", "hbx_enrollment_members" => "$hbx_enrollment_members"}},
  {"$lookup" => {
    "from" => "families",
    "localField" => "family_id",
    "foreignField" => "_id",
    "as" => "family"
  }},
  {"$unwind" => "$family"},
  {"$unwind" => "$family.family_members"},
  {"$unwind" => "$hbx_enrollment_members"},
  {"$project" => {
      "family_id" => "$family_id",
      "person_id" => "$family.family_members.person_id",
      "applicant_id" => "$hbx_enrollment_members.applicant_id",
      "person_and_member_match" => {"$eq" => ["$family.family_members._id", "$hbx_enrollment_members.applicant_id"]},
    }
  },
  {"$match" => {"person_and_member_match" => true}},
  {"$project" => {"_id" => "$person_id", "total" => {"$sum" => 1}}}
])

post_11_1_ids = post_11_1_purchases.map do |rec|
  rec["_id"]
end

post_11_1_purchase_set = Set.new(post_11_1_ids)

active_renewals_set = all_enrolled_people_set & renewal_candidate_set & post_11_1_purchase_set

passive_renewals_set = (all_enrolled_people_set & renewal_candidate_set & pre_11_1_purchase_set) - active_renewals_set

puts "Total Member Enrolled(2022) Count: #{all_enrolled_people_set.size}"
puts "Total New Member/Consumer selected 2022 enrollments after 11/1/2021 : #{new_member_set.size}"
puts "Total Re-Enrolled(2022) Member: #{re_enrolled_member_set.size}"
puts "Total Active Renewed(2022) Member: #{active_renewals_set.size}"
puts "Total Auto Renewed(2022) Member: #{passive_renewals_set.size}"

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

families = Family.all
total_families_count = families.count
families_per_iteration = 10_000.0
number_of_iterations = (total_families_count / families_per_iteration).ceil
counter = 0

while counter < number_of_iterations
  file_name = "#{Rails.root}/number_of_submitted_applications_ie_total_families_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = families_per_iteration * counter
  total_families(families, file_name, offset_count)
  counter += 1
end
puts "6. Number of Submitted Applications (gross). Total number of families in the system are: #{total_families_count}"

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
@state_at = TimeKeeper.start_of_exchange_day_from_utc(prev_day)
@end_at = TimeKeeper.end_of_exchange_day_from_utc(prev_day)
users = User.all.where(:created_at => { "$gte" => @state_at, "$lte" => @end_at })
total_user_count = users.count
users_per_iteration = 10_000.0
number_of_iterations = (total_user_count / users_per_iteration).ceil
counter = 0
@total_user_counter = 0

while counter < number_of_iterations
  file_name = "#{Rails.root}/number_of_user_accounts_created_yesterday_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = users_per_iteration * counter
  process_users(users, file_name, offset_count)
  counter += 1
end

puts "6.1 Number of Accounts created on a single day(Accounts Created). Total number of Users created yesterday: #{@total_user_counter}"

def process_families_with_no_external_id(families, file_name, offset_count)
  field_names = ["PrimaryHbxID", "PersonFullName", "HasStaffRole?"]
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    families.no_timeout.limit(10_000).offset(offset_count).inject([]) do |_dummy, family|
      person = family&.primary_person
      if person.present? && person.hbx_staff_role.blank?
        csv << [person.hbx_id, person.full_name, person.hbx_staff_role.present?]
        @total_new_families_count += 1
      end
    rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end

families = Family.all.where(:created_at => { "$gte" => @state_at, "$lte" => @end_at }, external_app_id: nil)
total_new_families_count = families.count
families_per_iteration = 10_000.0
number_of_iterations = (total_new_families_count / families_per_iteration).ceil
counter = 0
@total_new_families_count = 0

while counter < number_of_iterations
  file_name = "#{Rails.root}/number_of_accounts_with_no_external_id_created_yesterday_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = families_per_iteration * counter
  process_families_with_no_external_id(families, file_name, offset_count)
  counter += 1
end

puts "6.1B Number of new Accounts created on a single day(No external app id). Total number of new accounts created yesterday: #{@total_new_families_count}"


prev_day = TimeKeeper.date_of_record.yesterday
@state_at = TimeKeeper.start_of_exchange_day_from_utc(prev_day)
@end_at = TimeKeeper.end_of_exchange_day_from_utc(prev_day)
@total_submitted_count = 0

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

families = Family.all.where(:created_at => { "$gte" => @state_at, "$lte" => @end_at })
families_per_iteration = 10_000.0
number_of_iterations = (families.count / families_per_iteration).ceil
counter = 0

while counter < number_of_iterations
  file_name = "#{Rails.root}/applications_submitted_ie_number_of_families_created_yesterday_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = families_per_iteration * counter
  process_families(families, file_name, offset_count)
  counter += 1
end

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

applications = FinancialAssistance::Application.where(:submitted_at => { "$gte" => @state_at, "$lte" => @end_at })
applications_per_iteration = 10_000.0
number_of_iterations = (applications.count / applications_per_iteration).ceil
counter = 0

while counter < number_of_iterations
  file_name = "#{Rails.root}/applications_submitted_ie_number_of_applications_submitted_yesterday_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = applications_per_iteration * counter
  process_applications(applications, file_name, offset_count)
  counter += 1
end

puts "6.2  Applications Submitted, the combined total number of families created yesterday and number of applications submitted yesterday: #{@total_submitted_count}"


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

people = Person.all.where(:"consumer_role.is_applying_coverage" => true)
total_count = people.count
people_per_iteration = 10_000.0
number_of_iterations = (total_count / people_per_iteration).ceil
counter = 0
@total_member_counter_for_coverage = 0

while counter < number_of_iterations
  file_name = "#{Rails.root}/consumers_on_applications_submitted_ie_people_applying_for_coverage_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = people_per_iteration * counter
  process_people(people, file_name, offset_count)
  counter += 1
end

puts "7. Consumers on Applications Submitted (gross). Count of people that are applying for coverage: #{@total_member_counter_for_coverage}"


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

families = Family.where(:"households.tax_households" => { "$elemMatch" => { :"effective_ending_on" => nil, :"effective_starting_on".gte => Date.new(2022) } })
total_count = families.count
families_per_iteration = 10_000.0
number_of_iterations = (total_count / families_per_iteration).ceil
counter = 0
@total_member_counter_medicaid_or_chip = 0

while counter < number_of_iterations
  file_name = "#{Rails.root}/consumers_determined_eligible_for_medicaid_or_chip_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = families_per_iteration * counter
  process_ivl_families_medicaid_or_chip(families, file_name, offset_count)
  counter += 1
  puts "Counter: #{counter}, TotalMemberCounter: #{@total_member_counter_medicaid_or_chip}"
end
puts "8. Consumers Determined Eligible for Medicaid/CHIP (gross). Total number of family members that are found eligible for MedicAid or CHIP are: #{@total_member_counter_medicaid_or_chip}"



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

valid_people = Person.where(:is_incarcerated.ne => true, :"consumer_role.is_applying_coverage" => true, :"addresses.state" => "ME", :"consumer_role.lawful_presence_determination.citizen_status".in => ["us_citizen", "alien_lawfully_present", "naturalized_citizen"])
families = Family.where(:'family_members.person_id'.in => valid_people.pluck(:id))
total_count = families.count
families_per_iteration = 10_000.0
number_of_iterations = (total_count / families_per_iteration).ceil
counter = 0
@total_member_counter_with_qhp = 0

while counter < number_of_iterations
  file_name = "#{Rails.root}/consumers_eligible_for_qhp_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = families_per_iteration * counter
  process_ivl_families_with_qhp(families, file_name, offset_count)
  counter += 1
  puts "Counter: #{counter}, TotalMemberCounter: #{@total_member_counter_with_qhp}"
end
puts "9. Consumers Eligible for QHP (gross). Total number of family members that eligible for QHP are: #{@total_member_counter_with_qhp}"


def process_ivl_families_with_qhp_assistance(families, file_name, offset_count)
  field_names = ["PrimaryHbxID", "PrimaryFullName", "TaxHouseholdAPTC", "AptcMemberFullName", "IsIaEligible(APTC)", "CSR"]
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    families.no_timeout.limit(10_000).offset(offset_count).inject([]) do |_dummy, family|
      primary = family.primary_person
      thh = family.latest_household.tax_households.where(effective_ending_on: nil, :"effective_starting_on".gte => Date.new(2022)).first
      thhm_aptc_members = thh&.tax_household_members.where(is_ia_eligible: true)
      if thh.present? && thhm_aptc_members.present?
        thhm_aptc_members = thh.tax_household_members.where(is_ia_eligible: true)
        if thhm_aptc_members.present?
          thhm_aptc_members.each do |aptc_thhm|
            csv << [primary.hbx_id, primary.full_name, thh&.latest_eligibility_determination&.max_aptc, aptc_thhm&.person&.full_name, aptc_thhm&.is_ia_eligible, aptc_thhm&.csr_eligibility_kind]
          end
        end
        @total_member_counter_qhp_assistance += thhm_aptc_members.count
      end
      rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end

families = Family.where(:"households.tax_households" => { "$elemMatch" => { :"effective_ending_on" => nil, :"effective_starting_on".gte => Date.new(2022) } })
total_count = families.count
families_per_iteration = 10_000.0
number_of_iterations = (total_count / families_per_iteration).ceil
counter = 0
@total_member_counter_qhp_assistance = 0

while counter < number_of_iterations
  file_name = "#{Rails.root}/consumers_determined_eligible_for_aptc_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter + 1}.csv"
  offset_count = families_per_iteration * counter
  process_ivl_families_with_qhp_assistance(families, file_name, offset_count)
  counter += 1
  puts "Counter: #{counter}, TotalMemberCounter: #{@total_member_counter_qhp_assistance}"
end
puts "9.1. Consumers Eligible for QHP, with Financial Assistance (gross). Total number of family members that are found eligible for APTC(insurance_assistance) are: #{@total_member_counter_qhp_assistance}"

CSV.open("#{Rails.root}/CMS_daily_report_summary.csv", "w", force_quotes: true) do |csv|
  data =[
      ["","",""],
      ["","CMS Reporting Summary",""],
      ["","",""],
      ["","Total Plan Selections (net)", all_enrolled_people_set.size],
      ["","New Consumers (net)", new_member_set.size],
      ["","Total Re-enrollees (net)", re_enrolled_member_set.size],
      ["","Active Re-enrollees (net)", active_renewals_set.size],
      ["","Automatic Re-enrollees (net)", passive_renewals_set.size],
      ["","Number of Submitted Applications (gross)", total_families_count],
      ["","Number of Accounts created on a single day(Accounts Created)", @total_user_counter],
      ["","Number of Accounts created on a single day(No external app id)", @total_new_families_count],
      ["","Applications Submitted", @total_submitted_count],
      ["","Consumers on Applications Submitted (gross)", @total_member_counter_for_coverage],
      ["","Consumers Determined Eligible for Medicaid/CHIP (gross)", @total_member_counter_medicaid_or_chip],
      ["","Consumers Eligible for QHP (gross)", @total_member_counter_with_qhp],
      ["","Consumers Eligible for QHP, with Financial Assistance (gross)", @total_member_counter_qhp_assistance]
  ]
  data.each do |da|
    csv << da
  end
end
