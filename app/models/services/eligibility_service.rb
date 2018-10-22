module Services
  class EligibilityService

    attr_accessor :enrollment, :aptc_values, :family

    def initialize
    end

    def apply_aptc
      applied_aptc_amt = calculate_applied_aptc
      enrollment.applied_aptc_amount = applied_aptc_amt

      if applied_aptc_amt == aptc_values[:applied_aptc].to_f
        enrollment.elected_aptc_pct = (aptc_values[:applied_percentage].to_f/100.0)
      else
        enrollment.elected_aptc_pct = (applied_aptc_amt / aptc_values[:"max_aptc"].to_f)
      end
      enrollment
    end

    def calculate_applied_aptc
      [calculate_available_aptc, aptc_values[:applied_aptc].to_f, calculate_ehb_premium].min
    end

    def calculate_ehb_premium
      (enrollment.total_premium * enrollment.plan.ehb)
    end

    def calculate_available_aptc
      active_thh_for_enrollment_year.total_aptc_available_amount_for_enrollment(enrollment)
    end

    def active_thh_for_enrollment_year
      family.active_household.latest_active_thh_with_year(enrollment_year)
    end

    def create_eligibilies
    end

    private

    def enrollment_year
      enrollment.effective_on.year
    end
  end
end
