class PoliciesController < ApplicationController

  def home
    @policy_enrollments=IvlPolicie::PoliciesEnrollment.all
    @policy_seps=IvlPolicie::PoliciesSeps.all
    @policy_covered_lives=IvlPolicie::PoliciesDiscontinuedReinstatedCoveredLives.all
    @policy_totalaccounts=IvlPolicie::PolicyTotalAccounts.all
    @policy_annual_enrollments=IvlPolicie::PolicyAnnualEnrollmentType.all
    @policy_annual_carriers=IvlPolicie::PolicyAnnualCarrierType.all
    @metal_types=IvlPolicie::PolicyTotalMetalTypes.all
    @policy_annual_aptc=IvlPolicie::PolicyAnnualAptc.all
    @policy_family=IvlPolicie::PolicyFamily.all
    @policy_csr=IvlPolicie::PolicyCsr.all
    @policy_overall=IvlPolicie::PolicyOverall.all

  end

  def policies_more_info

  end
end