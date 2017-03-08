class IvlsController < ApplicationController

  def home
    @enrollments=IvlCovered::EnrollmentType.all
    @seps=IvlCovered::SepType.all
    @discontinuedreinstatedlives=IvlCovered::SepType.all
    @totalaccounts=IvlCovered::TotalAccounts.all
    @annual_enrollments=IvlCovered::AnnualEnrollmentType.all
    @annual_carriers=IvlCovered::AnnualCarrierType.all
    @covered_lives=IvlCovered::DiscontinuedReinstatedCoveredLives.all

  end

end