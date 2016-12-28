class DashboardsController < ApplicationController

def home
  @fundtransfer=CioDashboard::FundTransfer.all
  @pipeline = CioDashboard::Pipeline.pipeline_dashboard_stats
  @redmine=CioDashboard::Redmine.all
  @events=CioDashboard::UpcomingEvent.all
end

end
