# frozen_string_literal: true

module Factories
  class EligibilityFactory

    def initialize(enrollment_id, selected_aptc = nil)
      @enrollment = HbxEnrollment.find(enrollment_id)
      @selected_aptc = selected_aptc
      set_initializers
    end

    def fetch_available_eligibility
      available_eligibility_hash = fetch_available_aptc.merge(fetch_csr)
      total_aptc = available_eligibility_hash[:aptc].values.inject(0, :+)
      available_eligibility_hash.merge({:total_available_aptc => total_aptc})
    end

    def fetch_applicable_aptc
      [@selected_aptc, @ehb_premium].min if @product && @selected_aptc
    end

    private

    def set_initializers
      @family = @enrollment.family
      @product = fetch_product
      return unless @product
      @premium_amount = @enrollment.total_premium
      @ehb_premium = @enrollment.total_premium * @product.ehb
    end

    def fetch_product
      @enrollment.product_id ? @enrollment.product : nil
    end

    def shopping_member_ids
      @enrollment.hbx_enrollment_members.pluck(:applicant_id).map(&:to_s)
    end

    def tax_households
      @family.active_household.tax_households
    end

    def shopping_tax_members
      tax_households.flat_map(&:tax_household_members).select { |thhm| shopping_member_ids.include?(thhm.applicant_id.to_s) }
    end

    def any_aptc_ineligible?
      shopping_tax_members.map(&:is_ia_eligible?).include?(false)
    end

    def fetch_available_aptc
      # TODO: Refactor accordingly once BenchMark code is merged to Base branch
      # 1. What if one of the shopping members does not exist in any tax_households
      aptc = tax_households.inject({}) do |aptc_hash, tax_h|
        aptc_hash_thh = tax_h.aptc_available_amount_by_member
        aptc_hash.merge!(aptc_hash_thh) unless aptc_hash_thh.empty?
        aptc_hash
      end

      final_aptc = shopping_member_ids.inject({}) do |required_aptc_hash, member_id|
        required_aptc_hash.merge!(aptc.slice(member_id.to_s))
      end

      {:aptc => final_aptc}
    end

    def prioritized_csr(csr_kinds)
      if csr_kinds.include?('csr_100')
        'csr_100'
      elsif csr_kinds.include?('csr_94')
        'csr_94'
      elsif csr_kinds.include?('csr_87')
        'csr_87'
      elsif csr_kinds.include?('csr_73')
        'csr_73'
      else
        'csr_0'
      end
    end

    def fetch_csr
      return {:csr => 'csr_100'} if (shopping_tax_members.count != shopping_member_ids.count) || any_aptc_ineligible?

      csr_kinds = tax_households.map(&:current_csr_eligibility_kind)
      {:csr => prioritized_csr(csr_kinds)}
    end
  end
end
