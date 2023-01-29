# frozen_string_literal: true

# This script updates benchmark values for a specific cases where benchmark values are calculated with wrong rating area for a specific set
# bundle exec rails runner script/update_benchmark_values_for_thh_enrs_with_wrong_rating_area.rb

# This script is really an expection. Even though we are updating Benchmark Values for 2022 Enrollments we are not looking for RatingAddress at the
# time of Enrollment creation because somehow Addresses are recreated instead of update.

def benchmark_premiums_errors(benchmark_premiums_result)
  if benchmark_premiums_result.failure.is_a?(Dry::Validation::Result)
    benchmark_premiums_result.failure.errors.to_h
  else
    benchmark_premiums_result.failure
  end
end

def construct_hh_hash(old_tax_hh_enrs, family, enrollment, enrolled_family_member_ids)
  old_tax_hh_enrs.inject([]) do |result, tax_hh_enr|
    members_hash = (tax_hh_enr.tax_household.aptc_members.map(&:applicant_id) & enrolled_family_member_ids).inject([]) do |member_result, member_id|
      family_member = family.family_members.where(id: member_id).first

      member_result << {
        family_member_id: member_id,
        coverage_start_on: enrollment.hbx_enrollment_members.where(applicant_id: member_id).first&.coverage_start_on,
        relationship_with_primary: family_member.primary_relationship
      }

      member_result
    end
    next result if members_hash.blank?

    result << {
      household_id: tax_hh_enr.tax_household_id.to_s,
      members: members_hash
    }
    result
  end
end

def fetch_old_thh_info(th_enrollment)
  [th_enrollment.household_benchmark_ehb_premium, th_enrollment.health_product_hios_id, th_enrollment.dental_product_hios_id,
   th_enrollment.household_health_benchmark_ehb_premium, th_enrollment.household_dental_benchmark_ehb_premium]
end

def find_enrollments(person)
  person.families.inject([]) do |enrollments, family|
    enrollments + family.hbx_enrollments.by_year(2022).where(
      :aasm_state.nin => ['shopping', 'coverage_canceled'],
      :product_id.ne => nil,
      coverage_kind: 'health',
      :consumer_role_id.ne => nil
    ).select { |enr| enr.subscriber.person.id == person.id }
  end
end

def identify_slcsp_premiums(family, enrollment, households_hash)
  payload = {
    family_id: family.id,
    effective_date: enrollment.effective_on,
    households: households_hash
  }

  ::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts.new.call(payload)
end

def process_enrollment(enrollment, csv, person)
  family = enrollment.family
  enrolled_family_member_ids = enrollment.hbx_enrollment_members.map(&:applicant_id)
  update_benchmark_premiums(family, enrollment, enrolled_family_member_ids, csv, person)
end

def process_enrollment_subscriber_hbx_ids
  file_name = "#{Rails.root}/update_benchmark_values_for_thh_enrs_with_wrong_rating_area_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
  counter = 0

  field_names = %w[person_hbx_id enrollment_hbx_id enrollment_effective_on enrollment_aasm_state rating_address_info
                   old_thh_enr_household_benchmark_ehb_premium old_thh_enr_health_product_hios_id old_thh_enr_dental_product_hios_id
                   old_thh_enr_household_health_benchmark_ehb_premium old_thh_enr_household_dental_benchmark_ehb_premium
                   new_thh_enr_household_benchmark_ehb_premium new_thh_enr_health_product_hios_id new_thh_enr_dental_product_hios_id
                   new_thh_enr_household_health_benchmark_ehb_premium new_thh_enr_household_dental_benchmark_ehb_premium]

  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    @logger.info "Total number of subscribers: #{subscriber_hbx_ids.count}"

    subscriber_hbx_ids.each do |hbx_id|
      counter += 1
      @logger.info "Processed #{counter} subscriber enrollments" if counter % 50 == 0
      @logger.info "----- PersonHbxID: #{hbx_id} - Processing Subscriber"
      person = Person.by_hbx_id(hbx_id).first
      eligible_enrollments = find_enrollments(person)
      eligible_enrollments.each do |enrollment|
        process_enrollment(enrollment, csv, person)
      rescue StandardError => e
        @logger.info "----- PersonHbxID: #{hbx_id} EnrollmentHbxID: #{enrollment.hbx_id} - Error raised processing enrollment, error: #{e}, backtrace: #{e.backtrace}"
      end
    rescue StandardError => e
      @logger.info "----- PersonHbxID: #{hbx_id} - Error raised processing subscriber, error: #{e}, backtrace: #{e.backtrace}"
    end
  end
end

def subscriber_hbx_ids
  %w[1036267 1007062 1014799 1064724 1045143 1037828 1044175 1073042 1032809 1002098 1013413 1026659 1057033 1065723 1011448 1053459 1053195 1061205 1022186 1016166 1043143 1026203 1010239 1039429 1024060 1029675 1031939 1023189 1027371 1015423
     1009942 1022395 1051162 1062478 1016884 1057219 1066458 1013274 1060827 1017953 1017005 1041194 1042567 1041471 1003989 1017777 1007226 1020258 1056105 1022006 1063343 1036235 1062496 1063594 1067658 1054559 1037787 1031257 1041938 1027341
     1041709 1019142 1059597 1007909 1030192 1071976 1011061 1031545 1068624 1037413 1072451 1040836 1041848 1071235 1060156 1014430 1042082 1021436 1005815 1003489 1059543 1033933 1009222 1053141 1027849 1040972 1071556 1006473 1030885 1036450
     1027402 1045323 1016078 1062658 1041436 1012080 1009613 1074500 1060886 1011222 1039956 1041023 1011896 1047002 1032384 1056598 1052038 1046618 1050148 1071924 1019446 1026289 1069901 1038761 1070499 1006659 1057048 1074200 1012448 1031752
     1072774 1008285 1045384 1007711 1048666 1039236 1002351 1024973 1073066 1029633 1061985 1022352 1016296 1005302 1072182 1046390 1029873 1039625 1057995 1022935 1065014 1070688 1069703 1024787 1045750 1069909 1062941 1015127 1029622 1039661
     1020760 1036195 1000842 1025383 1047031 1010886 1006628 1018706 1022247 1065671 1041572 1023050 1005986 1005789 1057435 1013355 1069782 1042857 1005361 1059588 1047339 1056058 1047593 1027009 1043162 1037626 1068556 1009216 1064166 1067770
     1057200 1047262 1027918 1064272 1101631 1004316 1002417 1037844 1068306 1037999 1067611 1007914 1065771 1101555 1061719 1100650 1071855 1040751 1008751 1008220 1071575 1100379 1051783 1054303 1045637 1042728 1005042 1039578 1005903 1055490
     1014573 1100341 1026720 1051010 1064897 1015651 1026988 1039839 1024397 1041037 1040478 1107645 1019897 1003106 1018603 1053434 1032883 1044074 1066420 1062688 1008132 1057667 1036051 1010796 1049080 1004177 1035338 1069231 1058346 1115732
     1068716 1037961 1101080 1066976 1117472 1071326 1117817 1054883 1040163 1118649 1118666 1030958 1025443 1064998 1116395 1025067 1118035 1060171 1121610 1062522 1070754 1014257 1008105 1058225 1065598 1070437 1116496 1059479 1106715 1112558
     1018327 1123126 1013614 1036440 1123366 1123408 1123849 1123874 1123938 1123949 1123994 1124135 1124151 1105462 1019249 1036614 1027899 1020421 1017383 1066524 1064735 1033274 1071115 1033012 1054529 1114535 1011637 1037000 1009492 1029982
     1073728 1106492 1121579 1055571 1051094 1025347 1026785 1115737 1128257 1038763 1048851 1068162 1019123 1104623 1054972 1038853 1072476 1121503 1129012 1119185 1125806 1052860 1065399 1006652 1135030 1115061 1136053 1106492 1112551 1137062
     1034321 1022880 1034925 1055042 1073413 1030912 1069040 1054544 1137704 1122311 1068422 1024838 1013274 1138346 1069231 1046618 1133656 1129024 1124197 1009613 1022247 1139166 1042918 1141963 1142266 1109433 1024060 1056571 1145361 1037413
     1127289 1136847 1145147 1138561 1056776 1146180 1051162 1016860 1100650 1100379 1063084 1116496 1008132 1148346 1007576 1062669 1114442 1040552 1070280 1023369 1073007 1019754 1154259 1154262 1151426 1030305 1011099 1018706 1151183 1059543
     1154938 1157918 1003992 1059323 1059543 1155549 1116053 1112558 1167074 1167690 1166539 1168571 1170618 1170622 1007914 1171691 1169218 1172587 1172800 1173264 1166740 1018266 1021976 1018327 1151426 1176513 1178969 1176504 1054487 1174201
     1181721 1016078 1187075 1062478 1137293 1189546 1190645 1018808 1193066 1027888 1045637 1193946 1020260 1197737 1007062 1067658 1053434 1206338 1207208 1040836 1112366 1105462 1195998 1161715 1150744 1060171 1208837 1220708 1173264 1167690
     1014182 1005986]
end

def tax_household_enrollment_are_created_as_part_of_migration?(old_tax_hh_enrs, enrollment)
  old_tax_hh_enrs.any? { |thh_enr| thh_enr.created_at > (enrollment.created_at + 5.seconds) }
end

# rubocop:disable Metrics/AbcSize
def update_benchmark_premiums(family, enrollment, enrolled_family_member_ids, csv, person)
  rating_address_info = family.primary_person.rating_address.attributes.slice(:address_1, :county, :state, :zip)
  old_tax_hh_enrs = TaxHouseholdEnrollment.where(enrollment_id: enrollment.id)

  if old_tax_hh_enrs.blank?
    @logger.info "---------- PersonHbxID: #{person.hbx_id}, EnrHbxID: #{enrollment.hbx_id} - No TaxHouseholdEnrollments"
    return
  end

  unless tax_household_enrollment_are_created_as_part_of_migration?(old_tax_hh_enrs, enrollment)
    @logger.info "---------- PersonHbxID: #{person.hbx_id}, EnrHbxID: #{enrollment.hbx_id} - None of the TaxHouseholdEnrollments are created as part of migration"
    return
  end

  households_hash = construct_hh_hash(old_tax_hh_enrs, family, enrollment, enrolled_family_member_ids)
  if households_hash.blank?
    @logger.info "---------- PersonHbxID: #{person.hbx_id}, EnrHbxID: #{enrollment.hbx_id} - Unable to construct Benchmark Premiums payload"
    return
  end

  benchmark_premiums_result = identify_slcsp_premiums(family, enrollment, households_hash)
  if benchmark_premiums_result.failure?
    errors = benchmark_premiums_errors(benchmark_premiums_result)
    @logger.info "---------- PersonHbxID: #{person.hbx_id}, EnrHbxID: #{enrollment.hbx_id} - BenchmarkPremiums issue errors: #{errors}"
    return
  end

  old_tax_hh_enrs.each do |th_enrollment|
    old_thh_info = fetch_old_thh_info(th_enrollment)
    household_info = benchmark_premiums_result.success.households.find { |household| household.household_id.to_s == th_enrollment.tax_household_id.to_s }
    next th_enrollment if household_info.nil?

    if update_not_needed?(household_info, th_enrollment)
      @logger.info "---------- PersonHbxID: #{person.hbx_id}, EnrHbxID: #{enrollment.hbx_id} - Update not needed as TaxHouseholdEnrollment information is same. TaxHousehold hbx_assigned_id: #{th_enrollment.tax_household.hbx_assigned_id}"
      next th_enrollment
    end
    update_thh_enr_and_members(th_enrollment, household_info)
    csv <<
      (
        [person.hbx_id, enrollment.hbx_id, enrollment.effective_on, enrollment.aasm_state, rating_address_info] +
        old_thh_info +
        [th_enrollment.household_benchmark_ehb_premium, th_enrollment.health_product_hios_id, th_enrollment.dental_product_hios_id,
         th_enrollment.household_health_benchmark_ehb_premium, th_enrollment.household_dental_benchmark_ehb_premium]
      )

    @logger.info "---------- PersonHbxID: #{person.hbx_id}, EnrHbxID: #{enrollment.hbx_id} - Enrollment Updated"
  end
end
# rubocop:enable Metrics/AbcSize

def update_not_needed?(household_info, th_enrollment)
  th_enrollment.household_benchmark_ehb_premium.to_d == household_info.household_benchmark_ehb_premium.to_d &&
    th_enrollment.health_product_hios_id == household_info.health_product_hios_id &&
    th_enrollment.dental_product_hios_id == household_info.dental_product_hios_id &&
    th_enrollment.household_health_benchmark_ehb_premium.to_d == household_info.household_health_benchmark_ehb_premium.to_d &&
    th_enrollment.household_dental_benchmark_ehb_premium&.to_d == household_info.household_dental_benchmark_ehb_premium&.to_d
end

def update_thh_enr_and_members(th_enrollment, household_info)
  th_enrollment.update!(
    household_benchmark_ehb_premium: household_info.household_benchmark_ehb_premium,
    health_product_hios_id: household_info.health_product_hios_id,
    dental_product_hios_id: household_info.dental_product_hios_id,
    household_health_benchmark_ehb_premium: household_info.household_health_benchmark_ehb_premium,
    household_dental_benchmark_ehb_premium: household_info.household_dental_benchmark_ehb_premium
  )

  th_enrollment.tax_household_members_enrollment_members.each do |member|
    hh_member = household_info.members.detect { |mmbr| mmbr.family_member_id == member.family_member_id }
    next member if hh_member.blank?

    member.update!(age_on_effective_date: hh_member.age_on_effective_date)
  end
end

@logger = Logger.new("#{Rails.root}/log/update_benchmark_values_for_thh_enrs_with_wrong_rating_area_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
start_time = DateTime.current
@logger.info "UpdateBenchmarkValuesForThhEnrsWithWrongRatingArea start_time: #{start_time}"
process_enrollment_subscriber_hbx_ids
end_time = DateTime.current
@logger.info "UpdateBenchmarkValuesForThhEnrsWithWrongRatingArea end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_f.ceil}"
