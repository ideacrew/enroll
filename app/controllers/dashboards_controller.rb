class DashboardsController < ApplicationController

def home
  @fundtransfer=CioDashboard::FundTransfer.all
  @pipeline=CioDashboard::Pipeline.all
  @pipeline=@pipeline.compact
  @redmine=CioDashboard::Redmine.all
  @events=CioDashboard::UpcomingEvent.all
end

end
