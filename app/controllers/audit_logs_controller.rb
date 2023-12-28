class AuditLogsController < ApplicationController

  def index
    @audit_logs = [{
                     id: 1,
                     eligibility: "OSSE",
                     outcome: "Granted",
                     performed_by: "test@test.com",
                     reason: "This is testing",
                     approved: "Yes",
                     created_at: Time.now.utc
                   },
                   {
                     id: 2,
                     eligibility: "OSSE",
                     outcome: "Granted",
                     performed_by: "test@test.com",
                     reason: "This is testing",
                     approved: "Yes",
                     created_at: Time.now.utc
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
      @audit_logs = [@audit_logs.last]
    end


  end
end
