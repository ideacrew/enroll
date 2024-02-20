# frozen_string_literal: true

# Handles Audit Log requests
class EventLogsController < ApplicationController
  before_action :check_hbx_staff_role

  def index
    @event_logs = EventLogs::MonitoredEvent.where(:_id.in => event_params)
    respond_to do |format|
      format.js
      format.csv do
        csv_data = render_to_string(partial: 'event_logs/export_csv', locals: { event_logs: @event_logs&.order(:event_time.desc)&.map(&:eligibility_details) })
        send_data csv_data, filename: 'event_logs.csv', type: 'text/csv', disposition: 'attachment'
      end
    end
  end

  private

  def event_params
    params.require(:events)
  end

  def check_hbx_staff_role
    redirect_to root_path, :flash => { :error => "You must be an HBX staff member" } unless current_user.has_hbx_staff_role?
  end
end
