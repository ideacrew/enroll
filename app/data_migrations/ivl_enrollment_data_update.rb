require File.join(Rails.root, "lib/mongoid_migration_task")

class IvlEnrollmentDataUpdate < MongoidMigrationTask
  def migrate
    # This rake task is to generate a list of ivl enrollments satisfying the following scenario:
    # Given a user has an active enrollment E1 with effective date X
    # When the user purchases a new enrollment E2 with effective date Y
    # And E2 is the same plan year
    # And E2 is the same market type
    # And E2 has the same subscriber
    # E2 effective date > E1 effective date > E2 submitted on date.
    # Then E1 is Canceled
    #IVL Enrollments should be transitioned from the Canceled state to the Terminated state.
    families=Family.by_enrollment_individual_market.where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::CANCELED_STATUSES)

    families.each do |family|
      enrollments=family.active_household.hbx_enrollments
      if enrollments.size >= 2
        canceled_enrollments=enrollments.where(aasm_state:"coverage_canceled").where(kind:"individual")
        if canceled_enrollments.size > 0
          other_enrollments = enrollments - canceled_enrollments
          other_enrollments = other_enrollments.select{|a| a.subscriber  && a.effective_on  && a.submitted_at  }

          if other_enrollments.size>0
            canceled_enrollments.each do |canceled_enrollment|
              if canceled_enrollment.kind && canceled_enrollment.kind == "individual" && canceled_enrollment.subscriber && canceled_enrollment.effective_on && canceled_enrollment.submitted_at
                kind = canceled_enrollment.kind

                person= canceled_enrollment.subscriber.person
                effective = canceled_enrollment.effective_on
                other_enrollments = other_enrollments.select{|a| a.kind == kind && a.subscriber.person == person && effective > a.submitted_at && effective < a.effective_on }
                if other_enrollments.size > 0
                  canceled_enrollment.update_attributes(aasm_state:"coverage_terminated")
                end
              end
            end
          end
        end
      end
    end
  end

end

