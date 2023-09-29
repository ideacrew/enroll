# frozen_string_literal: true

# The below report generates enrollments and their tax household enrollments information for a given renewal year with its predecessor enrollments information.

# Example for option 1: This will generate report for prospective year enrollments.
#   rails runner script/thh_enrollment_report.rb
# Example for option 2: This will generate report for enrollments for the given enrollment hbx_ids which are in the prospective year with their predecessor enrollments information.
#   rails runner script/thh_enrollment_report.rb '' '12873, 12876182, 38746378, 87456384'
# Example for option 3: This will generate report for enrollments for all the enrollments in the given year with their predecessor enrollments information.
#   rails runner script/thh_enrollment_report.rb '2024' ''
# Example for option 4: This will generate report for enrollments for the given enrollment hbx_ids in the given year with their predecessor enrollments information.
#   rails runner script/thh_enrollment_report.rb '2024' '12873, 12876182, 38746378, 87456384'

@field_names = [
  'Primary Person Hbx ID',
  'Primary Person Full Name',
  'Enrollment Hbx ID',
  'Enrollment Effective On',
  'Enrollment Aasm State',
  'Enrollment Applied Aptc Amount',
  'Enrollment Applied APTC percentage',
  'ThhEnr NEW Applied Aptc',
  'ThhEnr NEW Applied Aptcs SUM',
  'ThhEnr Group Ehb Premium',
  'ThhEnr Available Max Aptc',
  'Enrolled Aptc Members',
  'Predecessor Enrollment Hbx ID'
]

def total_applied_aptc_sum(thh_enrs)
  thh_enrs.select { |thh_enr| thh_enr.applied_aptc.present? && thh_enr.applied_aptc.positive? }.sum(&:applied_aptc)
end

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
def process_enrollments(enrollments, file_name, offset_count)
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << @field_names

    enrollments.offset(offset_count).limit(5_000).each do |hbx_enrollment|
      @enrollments_counter += 1
      p "Currently processed #{@enrollments_counter} number of enrollments" if @enrollments_counter % 1000 == 0
      primary_person = hbx_enrollment.family.primary_person
      tax_household_enrollments = hbx_enrollment.tax_household_enrollments
      applied_aptc_sum = total_applied_aptc_sum(tax_household_enrollments)
      predecessor_enrollment = hbx_enrollment.predecessor_enrollment

      tax_household_enrollments.each do |tax_hh_enr|
        all_aptc_members = tax_hh_enr.tax_household.tax_household_members.where(
          is_ia_eligible: true,
          :applicant_id.in => hbx_enrollment.hbx_enrollment_members.map(&:applicant_id)
        ).map(&:person).map(&:full_name).join(', ')

        csv << [
          primary_person.hbx_id,
          primary_person.full_name,
          hbx_enrollment.hbx_id,
          hbx_enrollment.effective_on,
          hbx_enrollment.aasm_state,
          hbx_enrollment.applied_aptc_amount,
          hbx_enrollment.elected_aptc_pct,
          tax_hh_enr.applied_aptc,
          applied_aptc_sum,
          tax_hh_enr.group_ehb_premium,
          tax_hh_enr.available_max_aptc,
          all_aptc_members,
          predecessor_enrollment&.hbx_id
        ]
      rescue StandardError => e
        p "Error raised processing enrollment: #{hbx_enrollment.hbx_id} with tax_hh_enr_id: #{tax_hh_enr.id} with error: #{e.message}"
      end
      next hbx_enrollment unless predecessor_enrollment

      predecessor_enr_thh_enrs = predecessor_enrollment.tax_household_enrollments
      applied_aptc_sum = total_applied_aptc_sum(predecessor_enr_thh_enrs)
      predecessor_enr_thh_enrs.each do |predecessor_thh_enr|
        all_aptc_members = predecessor_thh_enr.tax_household.tax_household_members.where(
          is_ia_eligible: true,
          :applicant_id.in => predecessor_enrollment.hbx_enrollment_members.map(&:applicant_id)
        ).map(&:person).map(&:full_name).join(', ')

        csv << [
          primary_person.hbx_id,
          primary_person.full_name,
          predecessor_enrollment.hbx_id,
          predecessor_enrollment.effective_on,
          predecessor_enrollment.aasm_state,
          predecessor_enrollment.applied_aptc_amount,
          predecessor_enrollment.elected_aptc_pct,
          predecessor_thh_enr.applied_aptc,
          applied_aptc_sum,
          predecessor_thh_enr.group_ehb_premium,
          predecessor_thh_enr.available_max_aptc,
          all_aptc_members,
          'N/A'
        ]
      rescue StandardError => e
        p "Error raised processing predecessor enrollment: #{predecessor_enrollment.hbx_id} with tax_hh_enr_id: #{predecessor_thh_enr.id} with error: #{e.message}"
      end

    rescue StandardError => e
      p "Error raised processing enrollment: #{hbx_enrollment.hbx_id} with error: #{e.message}"
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

renewal_year = if ARGV[0].present? && ARGV[0].respond_to?(:to_i)
                 ARGV[0].to_i
               else
                 TimeKeeper.date_of_record.year.next
               end

enrollments = if ARGV[1].present?
                ::HbxEnrollment.all.by_year(renewal_year).by_health.with_aptc.effectuated.where(
                  :hbx_id.in => ARGV[1].to_s.split(',').map(&:squish!)
                )
              else
                ::HbxEnrollment.all.by_year(renewal_year).by_health.with_aptc.effectuated
              end

total_count = enrollments.count
enrollments_per_iteration = 5_000.0
number_of_iterations = (total_count / enrollments_per_iteration).ceil
counter = 0
@enrollments_counter = 0

p "Total Number of Hbx Enrollments that need to be processed: #{total_count}"

while counter < number_of_iterations
  file_name = "#{Rails.root}/report_thh_enrs_info_for_renewal_enrs_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{counter.next}.csv"
  offset_count = enrollments_per_iteration * counter
  process_enrollments(enrollments, file_name, offset_count)
  counter += 1
end
