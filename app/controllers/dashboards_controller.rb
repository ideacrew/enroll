class DashboardsController < ApplicationController

def home
  @fundtransfer=CioDashboard::FundTransfer.fundtransfer_dashboard_stats
  @pipeline = CioDashboard::Pipeline.pipeline_dashboard_stats
  @redmine=CioDashboard::Redmine.redmine_dashboard_stats
  @events=CioDashboard::UpcomingEvent.uc_events_dashboard_stats
end

end