module Services
  class EligibilityService

    attr_accessor :hbx_enrollment
    attr_reader   :csr, :available_aptc , :coverage_year

    def initialize(enrollment=nil)
      if enrollment.present?
        @hbx_enrollment = enrollment
      end
    end

    def process(eligibility = true)
      if eligibility && hbx_enrollment.present?
        set_embed_objs
        @csr = find_applicable_csr_for({applicant_ids: shopping_family_member_ids})
        @available_aptc = calculate_available_aptc
        self
      else
        raise "No enrollment to process"
      end
    end

    def assign(aptc_values)
      if aptc_values
        applied_aptc_amt = calculate_applied_aptc(aptc_values)
        enrollment.applied_aptc_amount = applied_aptc_amt

        if applied_aptc_amt == aptc_values[:applied_aptc].to_f
          enrollment.elected_aptc_pct = (aptc_values[:applied_percentage].to_f/100.0)
        else
          enrollment.elected_aptc_pct = (applied_aptc_amt / aptc_values[:max_aptc].to_f)
        end
        enrollment
      else
        raise "Provide aptc values {applied_aptc: , applied_percentage: , max_aptc: , csr_amt:}"
      end
    end

    def set_embed_objs
      set_year
      set_family
      set_household
      set_tax_household
    end

    def find_tax_household_members(tax_household = nil)
      active_tax_household = tax_household.present? ? tax_household : @latest_tax_household

      if active_tax_household.present?
        active_tax_household.tax_household_members
      else
        raise "Tax household is not present"
      end
    end

    def calculate_applied_aptc(aptc_values)
      [calculate_available_aptc, aptc_values[:applied_aptc].to_f, calculate_ehb_premium].min
    end

    private

    def latest_csr_kind
      @latest_tax_household.latest_eligibility_determination.csr_eligibility_kind if @latest_tax_household.present?
    end

    def shopping_family_member_ids
      shopping_enrollment_members.present? ? shopping_enrollment_members.map(&:applicant_id) : []
    end

    def shopping_enrollment_members
      enrollment.hbx_enrollment_members
    end

    def calculate_ehb_premium
      (enrollment.total_premium * enrollment.plan.ehb)
    end

    def calculate_available_aptc
      @latest_tax_household.total_aptc_available_amount_for_enrollment(enrollment)
    end

    def enrollment
      unless hbx_enrollment.present?
        raise "Hbx Enrollment Missing!!!"
      end
      hbx_enrollment
    end

    def find_applicable_csr_for(enrollment = {})
      members = find_tax_household_members

      if members && enrollment[:applicant_ids].present?
        enrollment_members_in_thh = members.where(:applicant_id.in => enrollment[:applicant_ids])
        enrollment_members_in_thh.map(&:is_ia_eligible).include?(false) ? "csr_100" : latest_csr_kind
      end
    end

    def set_year
      raise "Effective_on Date is blank on enrollment" if hbx_enrollment.effective_on.nil?
      @coverage_year = hbx_enrollment.effective_on.year
    end

    def set_family
      raise "family is not present for given enrollment" unless hbx_enrollment.family.present?
      @family = hbx_enrollment.family
    end

    def set_household
      raise "household is not present for given enrollment" unless @family.active_household.present?
      @household = @family.active_household
    end

    def set_tax_household
      @latest_tax_household = @household.latest_active_thh_with_year(coverage_year)
    end
  end
end
