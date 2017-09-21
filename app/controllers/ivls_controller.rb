class IvlsController < ApplicationController

  def home
    @enrollments=IvlCovered::CoveredLivesMonth.all
    @seps=IvlCovered::SepType.all
    @discontinuedreinstatedlives=IvlCovered::SepType.all
    @annual_enrollments=IvlCovered::AnnualEnrollment.all
    @annual_carriers=IvlCovered::AnnualCarrierType.all
    @covered_lives=IvlCovered::DiscontinuedReinstatedCoveredLives.all
    @metal_types=IvlCovered::TotalMetalTypes.all
    @annual_status=IvlCovered::AnnualStatusType.all
    @age_groups=IvlCovered::OverallAgeGroups.all
    @overall_genders=IvlCovered::OverallGenderTypes.all
    @annual_covered_lives=IvlCovered::AnnualCoveredLives.all
    @annual_covered=IvlCovered::ActiveCoveredLives.all
    # @over_all_aptc=IvlCovered::OverallAptc.all
    # @totalaccounts=IvlCovered::TotalAccounts.all
  end

  def enrollment

  end
  
end