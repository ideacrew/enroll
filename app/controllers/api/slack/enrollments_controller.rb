class ApiSlackEnrollmentsController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :require_login
  skip_before_action :authenticate_user_from_token!
  skip_before_action :authenticate_me!

  ## test in slack with
  ## /enrollment-state hbx_id=20119053
  def enrollment_state
    token = params[:token]
    user_name = params[:user_name]
    allowed_users = ENV['ENROLLMENT_STATE_USERS'].split(',')

    ## validate the token AND make sure the user requesting it has privligdges
    if token == ENV['SLACK_API_TOKEN'] && allowed_users.include?(user_name)
      ## valid request
      ## var1=value1 var2=value2
      ## string is split into array split by spaces for processing
      inputs = params[:text].split(" ")
      inputs.each do |input|
        parts = input.gsub(/\s+/, "").split("=")
        if parts[0] == "hbx_id"
          @hbx_id = parts[1]
        end
        p parts
      end
      @output_lines = []

      ##run look up ... https://jenkins.priv.dchbx.org/job/enrollment-state/configure
      enr =  HbxEnrollment.by_hbx_id(@hbx_id)
      if enr.size == 0
        @output_lines.push("No enrollments found by policy id #{@hbx_id}")
      else
        enrollment =  HbxEnrollment.by_hbx_id(@hbx_id).first
        @output_lines.push("Enrollment ID: #{@hbx_id} workflow state transitions")
        enrollment.workflow_state_transitions.each do |hbx_em|
          @output_lines.push("#{hbx_em.transition_at.to_s} #{hbx_em.from_state} to #{hbx_em.to_state}")
        end
      end

      ## respond
      slack = Slack::Incoming::Webhooks.new params[:response_url]
      slack.post @output_lines.join("\r\n")
    else
      ## error out
      ## respond
      slack = Slack::Incoming::Webhooks.new params[:response_url]
      slack.post "Slack user with username #{user_name} does not have permission to run enrollment-state. Please contact #{ENV['SLACK_API_ADMIN']} with this error message to be given permission."
    end
  end
end
