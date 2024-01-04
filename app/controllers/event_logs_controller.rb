# frozen_string_literal: true

# Handles Audit Log requests
class EventLogsController < ApplicationController
  before_action :check_hbx_staff_role
  def index
    @event_logs = EventLogs::MonitoredEvent.fetch_event_logs(event_log_params)
    respond_to do |format|
      format.js
      format.csv do
        csv_data = render_to_string(partial: 'event_logs/export_csv', locals: { event_logs: @event_logs })
        send_data csv_data, filename: 'event_logs.csv', type: 'text/csv', disposition: 'attachment'
      end
    end
  end

  private

  def event_log_params
    params.permit(:subject_hbx_id, :event_category, :account, :event_start_date, :event_end_date)
  end

  def check_hbx_staff_role
    redirect_to root_path, :flash => { :error => "You must be an HBX staff member" } unless current_user.has_hbx_staff_role?
  end

end
