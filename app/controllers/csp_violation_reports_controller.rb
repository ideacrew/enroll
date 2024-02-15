
class CspViolationReportsController < ActionController::Base
  def create
    # Need to store violation in our db and go through them individually and fix our policies or put code
    Rails.logger.info request.body.read
  end
end
