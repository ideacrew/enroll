class IvlsController < ApplicationController

  def home
    @enrollments=IvlCovered::EnrollmentType.all
    @seps=IvlCovered::SepType.all
    @discontinuedreinstatedlives=IvlCovered::SepType.all
    @totalaccounts=IvlCovered::TotalAccounts.all
    @annual_enrollments=IvlCovered::AnnualEnrollmentType.all
    @annual_carriers=IvlCovered::AnnualCarrierType.all
    @covered_lives=IvlCovered::DiscontinuedReinstatedCoveredLives.all
    @metal_types=IvlCovered::TotalMetalTypes.all
    @annual_status=IvlCovered::AnnualStatusType.all
    @age_groups=IvlCovered::OverallAgeGroups.all
    @over_all_aptc=IvlCovered::OverallAptc.all
    @overall_genders=IvlCovered::OverallGenderTypes.all
    @annual_covered_lives=IvlCovered::AnnualCoveredLives.all
  end

end