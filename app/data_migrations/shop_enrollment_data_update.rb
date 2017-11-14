require File.join(Rails.root, "lib/mongoid_migration_task")

class ShopEnrollmentDataUpdate < MongoidMigrationTask
  def migrate
    # This rake task is to generate a list of shop enrollments satisfying the following scenario:
    # Given a user has an active enrollment E1 with effective date X
    # When the user purchases a new enrollment E2 with effective date Y
    # And E2 is the same plan year
    # And E2 is the same market type
    # And E2 has the same subscriber
    # E2 effective date > E1 effective date > E2 submitted on date.
    # Then E1 is Canceled
    # SHOP Enrollments should be transitioned from the Canceled state to the Termination_Pending if coverage end date is in the future, otherwise they should be transitioned to Terminated state.
    families=Family.by_enrollment_shop_market.where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::CANCELED_STATUSES)
    families.each do |family|
      enrollments=family.active_household.hbx_enrollments
      if enrollments.size >= 2
        canceled_enrollments=enrollments.where(aasm_state:"coverage_canceled").where(:kind.in => ["employer_sponsored", "employer_sponsored_cobra"])
        if canceled_enrollments.size > 0
          other_enrollments = enrollments - canceled_enrollments
          other_enrollments = other_enrollments.select{|a| a.subscriber  && a.effective_on  && a.submitted_at  }

          if other_enrollments.size>0
            canceled_enrollments.each do |canceled_enrollment|
              if canceled_enrollment.kind  && canceled_enrollment.subscriber && canceled_enrollment.effective_on && canceled_enrollment.submitted_at
                kind = canceled_enrollment.kind
                person= canceled_enrollment.subscriber.person
                effective = canceled_enrollment.effective_on
                other_enrollments = other_enrollments.select{|a| a.kind == kind && a.subscriber.person == person && effective > a.submitted_at && effective < a.effective_on }
                if other_enrollments.size > 0
                  if canceled_enrollment.terminated_on.present? && canceled_enrollment.terminated_on > TimeKeeper.datetime_of_record
                    canceled_enrollment.update_attributes(aasm_state:"coverage_termination_pending")
                  else
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
end






