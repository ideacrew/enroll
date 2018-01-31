module Parser
  class HsaParser
    include HappyMapper

    tag 'hsa'

    element :hsa_eligibility, String, tag: "hsaEligibility"
    element :employer_hsahra_contribution_indicator, String, tag: "employerHSAHRAContributionIndicator"
    element :emp_contribution_amount_for_hsa_or_hra, String, tag: "empContributionAmountForHSAOrHRA"

    def to_hash
      {
        hsa_eligibility: hsa_eligibility.gsub(/\n/,'').strip,
        employer_hsahra_contribution_indicator: employer_hsahra_contribution_indicator.gsub(/\n/,'').strip,
        emp_contribution_amount_for_hsa_or_hra: emp_contribution_amount_for_hsa_or_hra.gsub(/\n/,'').strip,
      }
    end
  end
end
