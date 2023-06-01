# frozen_string_literal: true

# This script generates a CSV report with information about Continuous Coverage Health Enrollments created on or after 2022/1/1 with TaxHouseholdEnrollments.
# This excludes enrollments in shopping or coverage_canceled state.
# bundle exec rails runner script/list_of_continuous_coverage_enrs.rb

# To run this on specific enrollments
# bundle exec rails runner script/list_of_continuous_coverage_enrs.rb enr_hbx_ids='127633, 1987222, 3746543'

def process_enrollment(enrollment, csv)
  thh_enrs = TaxHouseholdEnrollment.where(enrollment_id: enrollment.id)
  person = enrollment.family.primary_person

  enrollment_members_info = enrollment.hbx_enrollment_members.inject({}) do |haash, enr_member|
    haash[enr_member.person.full_name] = enr_member.coverage_start_on.to_s
    haash
  end

  if thh_enrs.present?
    thh_enrs.each do |thh_enr|
      thh = thh_enr.tax_household
      next thh_enr if thh.blank?

      valid_thh_members = thh.tax_household_members.where(:id.in => thh_enr.tax_household_members_enrollment_members.pluck(:tax_household_member_id))
      csv << [
        person.hbx_id,
        enrollment.hbx_id,
        enrollment.aasm_state,
        enrollment.total_premium.to_f,
        enrollment.effective_on,
        enrollment.product.ehb,
        enrollment.applied_aptc_amount.to_f,
        enrollment_members_info,
        valid_thh_members.map(&:person).map(&:full_name),
        thh_enr.household_benchmark_ehb_premium,
        thh_enr.health_product_hios_id,
        thh_enr.dental_product_hios_id,
        thh_enr.household_health_benchmark_ehb_premium,
        thh_enr.household_dental_benchmark_ehb_premium
      ]
    end
  else
    csv << [
      person.hbx_id,
      enrollment.hbx_id,
      enrollment.aasm_state,
      enrollment.total_premium.to_f,
      enrollment.effective_on,
      enrollment.product.ehb,
      enrollment.applied_aptc_amount.to_f,
      enrollment_members_info,
      'N/A',
      'N/A',
      'N/A',
      'N/A',
      'N/A',
      'N/A'
    ]
  end
end

def process_enrollment_hbx_ids
  file_name = "#{Rails.root}/list_of_thhenr_for_continuous_coverage_enrs.csv"
  field_names = %w[person_hbx_id
                   enrollment_hbx_id
                   enrollment_aasm_state
                   enrollment_total_premium
                   enrollment_effective_on
                   product_ehb
                   enrollment_applied_aptc_amount
                   enrollment_members_with_coverage_start_on
                   tax_household_members
                   household_benchmark_ehb_premium
                   health_product_hios_id
                   dental_product_hios_id
                   household_health_benchmark_ehb_premium
                   household_dental_benchmark_ehb_premium]

  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    enr_hbx_ids = find_enrollment_hbx_ids
    @logger.info "Total No. of enrollments count: #{enr_hbx_ids.count}"
    counter = 0
    enr_hbx_ids.each do |enr_hbx_id|
      counter += 1
      enrollment = HbxEnrollment.where(hbx_id: enr_hbx_id).first
      process_enrollment(enrollment, csv)
      @logger.info "Processed EnrollmentHbxId: #{enr_hbx_id}"
      @logger.info "Processed #{counter} number of Enrollments." if counter % 1000 == 0
    rescue StandardError => e
      @logger.info e.message
    end
  end
end

def find_enrollment_hbx_ids
  hbx_ids = ENV['enr_hbx_ids'].to_s.split(',').map(&:squish!)
  return hbx_ids if hbx_ids.present?

  HbxEnrollment.collection.aggregate(
    [
      {
        "$match" => {
          "hbx_enrollment_members" => {"$ne" => nil},
          "coverage_kind" => "health",
          "consumer_role_id" => {"$ne" => nil},
          "product_id" => {"$ne" => nil},
          "aasm_state" => {"$nin" => ['shopping', 'coverage_canceled']},
          "effective_on" =>  {"$gte" => Date.new(2022)}
        }
      },
      {
        "$project" => {
          "hbx_enrollment_members" => "$hbx_enrollment_members",
          "effective_on" => "$effective_on",
          "hbx_id" => "$hbx_id"
        }
      },
      {"$unwind" => "$hbx_enrollment_members"},
      {
        "$match" => {
          "$expr" => {
            "$ne" => [
              { "$dateToString" => { "format" => "%Y-%m-%d", date: "$hbx_enrollment_members.coverage_start_on" }},
              { "$dateToString": { "format": "%Y-%m-%d", date: "$effective_on" }}
            ]
          }
        }
      },
      "$group" => { "_id" => "$hbx_id"}
    ]
  ).map { |rec| rec['_id'] }
end

start_time = DateTime.current
@logger = Logger.new("#{Rails.root}/thhenr_for_continuous_coverage_enrs_log_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
@logger.info "Migration Report start_time: #{start_time}"
process_enrollment_hbx_ids
end_time = DateTime.current
@logger.info "Migration Report end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - start_time) * 24 * 60).to_i}"
