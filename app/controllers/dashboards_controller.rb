class DashboardsController < ApplicationController

def home
  @fundtransfer=CioDashboard::FundTransfer.all
  @pipeline=CioDashboard::Pipeline.all
  @redmine=CioDashboard::Redmine.all
  @events=CioDashboard::UpcomingEvent.all
end

end
