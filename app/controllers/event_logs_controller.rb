class EventLogsController < ApplicationController

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
    params.permit(:subject_hbx_id, :category, :account, :event_start_date, :event_end_date)
  end

end
