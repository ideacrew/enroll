# frozen_string_literal: true

# Handles Audit Log requests
class EventLogsController < ApplicationController
  before_action :check_hbx_staff_role

  def index
    @event_logs = EventLogs::MonitoredEvent.where(:_id.in => event_params).order(:event_time.desc)

    respond_to do |format|
      format.js
      format.csv { send_csv_data }
    end
  end

  private

  def event_params
    params[:events] || []
  end

  def check_hbx_staff_role
    redirect_to root_path, flash: { error: "You must be an HBX staff member" } unless current_user.has_hbx_staff_role?
  end

  def send_csv_data
    send_data(csv_data, filename: 'event_logs.csv', type: 'text/csv', disposition: 'attachment')
  end

  def csv_data
    EventLogs::MonitoredEvent.to_csv(@event_logs)
  end

  def event_params
    params[:events] || []
  end
end
