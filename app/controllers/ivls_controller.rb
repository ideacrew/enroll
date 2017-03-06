class IvlsController < ApplicationController

  def home
      @enrollments=IvlCovered::EnrollmentType.all
      @seps=IvlCovered::SepType.all
      @discontinuedreinstatedlives=IvlCovered::SepType.all
      @totalaccounts=IvlCovered::SepType.all
  end

end