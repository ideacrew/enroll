# frozen_string_literal: true

module HbxEnrollments
  # CalculateEffectiveOnForEnrollment is an interactor that determines the new effective date of an enrollment
  class CalculateEffectiveOnForEnrollment
    include Interactor

    before do
      context.fail!(message: "base_enrollment_effective_on is required") unless base_enrollment_effective_on.present?
      context.fail!(message: "system_date is required") unless system_date.present?
    end

    # Context Requires:
    # - base_enrollment_effective_on
    # - system_date
    def call
      context.new_effective_on = new_effective_on
    end

    private

    def new_effective_on
      # this condition is for self service APTC feature ONLY.
      day = 1
      if eligible_for_1_1_effective_date?
        year = base_enrollment_effective_on.year
        month = day = 1
      elsif base_enrollment_effective_on.year != system_date.year
        monthly_enrollment_due_on = override_enabled ? 31 : individual_enrollment_due_day_of_month
        condition = (Date.new(system_date.year, 11, 1)..Date.new(system_date.year, 12, monthly_enrollment_due_on)).include?(system_date.to_date)
        offset_month = condition ? 0 : 1
        year = base_enrollment_effective_on.year
        month = system_date.next_month.month + offset_month
      else
        offset_month = (system_date.day <= individual_enrollment_due_day_of_month || override_enabled) ? 1 : 2
        year = system_date.year
        month = system_date.month + offset_month
      end

      build_date(year, month, day)
    end

    # Checks if case is eligible for 1/1 effective date for Prospective Year's enrollments.
    def eligible_for_1_1_effective_date?
      last_eligible_date_for_1_1_effective_date = Date.new(system_date.year, system_date.end_of_year.month, individual_enrollment_due_day_of_month)
      base_enrollment_effective_on.year > system_date.year && HbxProfile.current_hbx.under_open_enrollment? && last_eligible_date_for_1_1_effective_date > system_date
    end

    def build_date(year, month, day)
      if month > 12
        year += 1
        month -= 12
      end

      DateTime.new(year, month, day, hour, min, sec)
    end

    def base_enrollment_effective_on
      @base_enrollment_effective_on ||= context.base_enrollment_effective_on
    end

    def system_date
      @system_date ||= context.system_date
    end

    def hour
      system_date.hour
    end

    def min
      system_date.min
    end

    def sec
      system_date.sec
    end

    def individual_enrollment_due_day_of_month
      @individual_enrollment_due_day_of_month ||= HbxProfile::IndividualEnrollmentDueDayOfMonth
    end

    def override_enabled
      EnrollRegistry[:fifteenth_of_the_month_rule_overridden].feature.is_enabled
    end
  end
end