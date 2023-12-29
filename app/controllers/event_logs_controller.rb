class EventLogsController < ApplicationController

  def index
    @event_logs = [{
                     id: 1,
                     eligibility: "OSSE",
                     outcome: "Granted",
                     performed_by: "test@test.com",
                     reason: "This is testing",
                     approved: "Yes",
                     created_at: Time.now.utc - 2.days
                   },
                   {
                     id: 2,
                     eligibility: "OSSE",
                     outcome: "Renewed",
                     performed_by: "test@test.com",
                     reason: "This is testing",
                     approved: "Yes",
                     created_at: Time.now.utc - 1.day
                   },
                   {
                     id: 3,
                     eligibility: "OSSE",
                     outcome: "Granted",
                     performed_by: "test@test.com",
                     reason: "This is testing",
                     approved: "Yes",
                     created_at: Time.now.utc
                   },
                   {
                     id: 4,
                     eligibility: "OSSE1",
                     outcome: "Granted",
                     performed_by: "test1@test.com",
                     reason: "This is testing",
                     approved: "Yes",
                     created_at: Time.now.utc
                   }]

    if params[:user_id].present?
      @event_logs = [@event_logs.last]
    end

    respond_to do |format|
      format.js
      format.csv do
        csv_data = render_to_string(partial: 'event_logs/export_csv', locals: { event_logs: @event_logs })
        send_data csv_data, filename: 'event_logs.csv', type: 'text/csv', disposition: 'attachment'
      end
    end
  end

end
