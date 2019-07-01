# frozen_string_literal: true

#This service can be used for all eligibilities related projects.
#Currently the development is done only for passive renewals.
#Further enhancements can be made for this service based on the projects - plan shopping controller, APTC tool, mixed household eligibility

module Services
  class IvlRenewalService

    attr_accessor :hbx_enrollment
    attr_reader   :csr, :available_aptc, :coverage_year

    def initialize(enrollment = nil)
      @hbx_enrollment = enrollment if enrollment.present?
    end

    def process(eligibility = true)
      raise "No enrollment to process" unless eligibility && hbx_enrollment.present?

      set_embed_objs
      @csr = find_applicable_csr_for({applicant_ids: shopping_family_member_ids})
      @available_aptc = calculate_available_aptc
      self
    end

    def assign(aptc_values)
      raise "Provide aptc values {applied_aptc: , applied_percentage: , max_aptc: , csr_amt:}" if aptc_values.empty?

      applied_aptc_amt = calculate_applied_aptc(aptc_values)
      enrollment.applied_aptc_amount = applied_aptc_amt

      enrollment.elected_aptc_pct = if applied_aptc_amt == aptc_values[:applied_aptc].to_f
                                      (aptc_values[:applied_percentage].to_f / 100.0)
                                    else
                                      (applied_aptc_amt / aptc_values[:max_aptc].to_f)
                                    end

      enrollment
    end

    def set_embed_objs
      set_year
      set_family
      set_household
      set_tax_household
    end

    def find_tax_household_members(tax_household = nil)
      active_tax_household = tax_household.presence || @latest_tax_household
      raise "Tax household is not present" if active_tax_household.blank?

      active_tax_household.tax_household_members
    end

    def applicable_aptc(aptc_values)
      return @applicable_aptc if @applicable_aptc.present?

      product_id = @hbx_enrollment.product.id.to_s
      applicable_aptc_service = ::Services::ApplicableAptcService.new(@hbx_enrollment.id, aptc_values[:applied_aptc].to_f, [product_id])
      @applicable_aptc ||= applicable_aptc_service.applicable_aptcs[product_id]
    end

    def calculate_applied_aptc(aptc_values)
      # We still consider AvailableAptc in this calculation because the
      # :applied_aptc(ElectedAptc) is given externally and not calculated by the EA.

      @calculate_applied_aptc ||= [calculate_available_aptc, applicable_aptc(aptc_values)].min
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
      (enrollment.total_premium * enrollment.product.ehb)
    end

    def init_available_eligibility_service
      @init_available_eligibility_service ||= ::Services::AvailableEligibilityService.new(@hbx_enrollment.id)
    end

    def calculate_available_aptc
      init_available_eligibility_service
      @calculate_available_aptc ||= init_available_eligibility_service.available_eligibility[:total_available_aptc]
    end

    def enrollment
      raise "Hbx Enrollment Missing!!!" if hbx_enrollment.blank?

      hbx_enrollment
    end

    def find_applicable_csr_for(enrollment = {})
      members = find_tax_household_members
      return if members && enrollment[:applicant_ids].present?

      enrollment_members_in_thh = members.where(:applicant_id.in => enrollment[:applicant_ids])
      enrollment_members_in_thh.map(&:is_ia_eligible).include?(false) ? "csr_100" : latest_csr_kind
    end

    def set_year
      raise "Effective_on Date is blank on enrollment" if hbx_enrollment.effective_on.nil?

      @coverage_year = hbx_enrollment.effective_on.year
    end

    def set_family
      raise "family is not present for given enrollment" if hbx_enrollment.family.blank?

      @family = hbx_enrollment.family
    end

    def set_household
      raise "household is not present for given enrollment" if @family.active_household.blank?

      @household = @family.active_household
    end

    def set_tax_household
      @latest_tax_household = @household.latest_active_thh_with_year(coverage_year)
    end
  end
end
