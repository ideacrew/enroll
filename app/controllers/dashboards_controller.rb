class DashboardsController < ApplicationController

def home
  @fundtransfers=CioDashboard::FundTransfer.fundtransfer_dashboard_stats
  @pipelines = CioDashboard::Pipeline.pipeline_dashboard_stats
  @redmines=CioDashboard::Redmine.redmine_dashboard_stats
  @events=CioDashboard::UpcomingEvent.uc_events_dashboard_stats
  @callcenters=CioDashboard::CallCenter.callcenter_dashboard_stats
  @webactivitys=CioDashboard::WebActivity.webactivity_dashboard_stats
  @majorprojects=CioDashboard::MajorProject.dashboard_stats
end

end