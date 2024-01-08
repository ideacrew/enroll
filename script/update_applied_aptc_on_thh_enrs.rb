# frozen_string_literal: true

# Updates the applied_aptc on aptc tax household enrollments for the given enrollment hbx_ids.
# @note
#   This script may update the applied_aptc and group_ehb_premium on the tax household enrollments.
#   This script is just used to update applied_aptc on the tax household enrollments only when
#   the thh enrs exist and are correct except for the applied_aptc and group_ehb_premium.
# @example Command to run the script: bundle exec rails runner script/update_applied_aptc_on_thh_enrs.rb '12873, 12876182, 38746378, 87456384'

def input_enrollment_hbx_ids(input_arg)
  input_arg.to_s.split(',').map(&:squish!)
rescue StandardError => e
  raise "Invalid input argument: #{input_arg}. Expected format: '12873, 12876182, 38746378, 87456384'. Raised error: #{e.message}"
end

@enrollment_hbx_ids = input_enrollment_hbx_ids(ARGV[0]).uniq

def file_name
  "#{Rails.root}/updated_thh_enrs_info_for_enrollments_report_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
end

def field_names
  [
    'Primary Person Hbx ID',
    'Primary Person Full Name',
    'Enrollment Hbx ID',
    'Enrollment Effective On',
    'Enrollment Aasm State',
    'Enrollment Applied Aptc Amount',
    'ThhEnr ID',
    'ThhEnr Current Applied Aptc',
    'ThhEnr New Applied Aptc',
    'ThhEnr Current Group Ehb Premium',
    'ThhEnr New Group Ehb Premium'
  ]
end

def hbx_enrollments
  @hbx_enrollments ||= ::HbxEnrollment.all.by_health.with_aptc.where(
    :hbx_id.in => @enrollment_hbx_ids
  )
end

def fetch_aptc_thh_enrs_info(enrollment)
  enrollment.aptc_tax_household_enrollments.inject({}) do |aptc_thh_enrs_info, thh_enr|
    aptc_thh_enrs_info[thh_enr.id] = {
      current_applied_aptc: thh_enr.applied_aptc,
      current_group_ehb_premium: thh_enr.group_ehb_premium
    }

    aptc_thh_enrs_info
  end
end

def process_enrollments
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names

    hbx_enrollments.each do |enrollment|
      current_thh_enrs_info = fetch_aptc_thh_enrs_info(enrollment)
      enrollment.update_tax_household_enrollment
      new_thh_enrs_info = fetch_aptc_thh_enrs_info(enrollment)

      primary = enrollment.family.primary_person

      current_thh_enrs_info.keys.each do |thh_enr_id|
        csv << [
          primary.hbx_id,
          primary.full_name,
          enrollment.hbx_id,
          enrollment.effective_on,
          enrollment.aasm_state,
          enrollment.applied_aptc_amount,
          thh_enr_id,
          current_thh_enrs_info[thh_enr_id][:current_applied_aptc],
          new_thh_enrs_info[thh_enr_id][:current_applied_aptc],
          current_thh_enrs_info[thh_enr_id][:current_group_ehb_premium],
          new_thh_enrs_info[thh_enr_id][:current_group_ehb_premium]
        ]
      end
    end
  end
end

process_enrollments
