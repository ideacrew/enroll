class EventLogsController < ApplicationController

  def index
    query = {}
    %w(subject_hbx_id category).each do |param|
      query[param.to_sym] = params[param.to_sym] if params[param.to_sym].present?
    end

    if params[:account].present?
      query["$or"] = [{ account_hbx_id: params[:account] }, { account_username: params[:account] }]
    end

    %w(event_start_date event_end_date).each do |param|
      if params[param.to_sym].present?
        query[:event_time] ||= {}
        query[:event_time].merge!({ "$#{param == 'event_start_date' ? 'gte' : 'lte'}" => params[param.to_sym] })
      end
    end

    @event_logs = query.present? ? EventLogs::MonitoredEvent.where(query) : EventLogs::MonitoredEvent.all
    respond_to do |format|
      format.js
      format.csv do
        csv_data = render_to_string(partial: 'event_logs/export_csv', locals: { event_logs: @event_logs })
        send_data csv_data, filename: 'event_logs.csv', type: 'text/csv', disposition: 'attachment'
      end
    end
  end

end
