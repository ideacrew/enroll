# frozen_string_literal: true

# Handles Audit Log requests
class EventLogsController < ApplicationController
  before_action :check_hbx_staff_role
  def index
    if params[:family]
      family = Family.find(params[:family])
      hbxes = family.family_members.map {|fm| fm.person.hbx_id}&.uniq
      family_logs = EventLogs::MonitoredEvent.where(:subject_hbx_id.in => hbxes)&.order(:event_time.desc)&.map(&:eligibility_details)
    end
    @event_logs = family_logs || EventLogs::MonitoredEvent.all&.map(&:eligibility_details)
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
    params.permit(:family)
  end

  def check_hbx_staff_role
    redirect_to root_path, :flash => { :error => "You must be an HBX staff member" } unless current_user.has_hbx_staff_role?
  end

end
