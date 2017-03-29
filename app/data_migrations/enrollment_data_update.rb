require File.join(Rails.root, "lib/mongoid_migration_task")

class EnrollmentDataUpdate < MongoidMigrationTask
  def migrate
    # This rake task is to generate a list of enrollments satisfying the following scenario:
    # Given a user has an active enrollment E1 with effective date X
    # When the user purchases a new enrollment E2 with effective date Y
    # And E2 is the same plan year
    # And E2 is the same market type
    # And E2 has the same subscriber
    # E2 effective date > E1 effective date > E2 submitted on date.
    # Then E1 is Canceled
    #IVL Enrollments should be transitioned from the Canceled state to the Terminated state.
    #SHOP Enrollments should be transitioned from the Canceled state to the Termination_Pending if coverage end date is in the future,
    #otherwise they should be transitioned to Terminated state.                                                                                                                                                                                                                                                                                  require 'csv'

      families=Family.where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::CANCELED_STATUSES)
      families.each do |family|
        enrollments=family.active_household.hbx_enrollments
        family.active_household.hbx_enrollments.where(aasm_state:"coverage_canceled").each do |canceled_enrollment|
        enrollments.each do |enrollment|
          if canceled_enrollment.kind == enrollment.kind
            puts canceled_enrollment.inspect
            puts enrollment.inspect
            cancel_member=canceled_enrollment.hbx_enrollment_members.where(is_subscriber:true).first
            reference_member=enrollment.hbx_enrollment_members.where(is_subscriber:true).first

            if cancel_member.id == reference_member.id
              cancel_effective=canceled_enrollment.effective_on
              reference_effective=enrollment.effective_on
              reference_submitted=enrollment.submitted_at
              if cancel_effective > reference_submitted && cancel_effective < reference_effective
                if canceled_enrollment.kind == "individual"
                  if canceled_enrollment.effective_on.year == enrollment.effective_on.year
                     enrollment.update_attributes(aasm_state:"coverage_terminated")
                  end
                elsif canceled_enrollment.kind == "employer_sponsored"
                  if canceled_enrollment.benefit_group.plan_year == enrollment.benefit_group.plan_year
                    if enrollment.terminated_on > TimeKeeper.datetime_of_record
                      enrollment.update_attributes(aasm_state:"coverage_termination_pending")
                    else
                      enrollment.update_attributes(aasm_state:"coverage_terminated")
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