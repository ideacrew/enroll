# Expected Outcome:
# 1. Enrollments should be changed from the Terminated to Canceled.
# 2. Coverage end date for affected enrollments should be equal to the enrollment effective date.
# 3. Provide an output identifying the following: Primary Subscriber HBX ID, E1 HBX ID, E1 effective date, E1 Market type, E2 HBX ID

require 'csv'

namespace :enrollment do
  
  desc "Clean Up: Enrollment should be Canceled"
  task :clean_up_enrollments_in_cancel_state_erroneously => :environment do
    file_name = "#{Rails.root}/clean_up_enrollments_in_cancel_state_erroneously.csv"
    field_names  = ["Subscriber HBX ID", "Cancel_enrollment_hbx_id", "Cancel_enrollment_effective_date", "Cancel_enrollment_market_type", "Reference_enrollment_hbx_id"]
    
    CSV.open(file_name, "w") do |csv|
    csv << field_names
    families=Family.where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::TERMINATED_STATUSES)

      families.each do |family|
        enrollments = family.active_household.hbx_enrollments
  
        family.active_household.hbx_enrollments.where(aasm_state:"coverage_terminated").each do |terminated_enrollment|
          enrollments.each do |enrollment|
            if terminated_enrollment.kind == enrollment.kind
              terminate_member = terminated_enrollment.hbx_enrollment_members.where(is_subscriber:true).first
              active_member = enrollment.hbx_enrollment_members.where(is_subscriber:true).first
              if terminate_member.present? && active_member.present?
                if terminate_member.id == active_member.id
                  terminate_effective = terminated_enrollment.effective_on
                  active_effective = enrollment.effective_on
                  terminated_submitted = terminated_enrollment.submitted_at
                  active_submitted = enrollment.submitted_at
                  #Proposed Conditions for data:
                  #1. X effective date = Y effective date.
                  if terminate_effective == active_effective
                    if terminate_effective.present? && active_submitted.present?
                      #2. E1 effective date > E2 submitted on date.
                      if terminate_effective > active_submitted.to_date
                        # Expected Outcome:
                        # 1. Enrollments should be changed from the Terminated to Canceled.
                         terminated_enrollment.update(aasm_state:'coverage_canceled')
                        # 2. Coverage end date for affected enrollments should be equal to the enrollment effective date.
                         terminated_enrollment.update(terminated_on:active_effective)
                        # 3. Provide an output identifying the following: Primary Subscriber HBX ID, E1 HBX ID, E1 effective date, E1 Market type, E2 HBX ID
                        csv << [active_member.person.hbx_id, terminated_enrollment.hbx_id, terminate_effective, terminated_enrollment.kind, enrollment.hbx_id]
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

    end
  end
end