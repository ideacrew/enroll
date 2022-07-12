class ApiSlackPoliciesController < ApplicationController
  protect_from_forgery with: :null_session

  ## test in slack with
  ## /policy-id-check hbx_id=20119053
  def policy_id_check
    token = params[:token]
    user_name = params[:user_name]
    allowed_users = ["davidplapper"]

    ## validate the token AND make sure the user requesting it has privligdges
    if token == "VQp4kgdXbMQJ2sqnOL0xIB6p" && allowed_users.include?(user_name)
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

      ##run look up ... copied from https://jenkins.priv.dchbx.org/job/policy-id-check/configure
      person = Person.where(hbx_id: @hbx_id).first
      @output_lines = []
      if person.nil?
        @output_lines.push("No person record")
      elsif person.primary_family.nil?
       @output_lines.push("No primary family")
      elsif person.primary_family.active_household.nil?
        @output_lines.push("No Active Household")
      elsif person.primary_family.active_household.hbx_enrollments.nil?
        @output_lines.push("No HBX Enrollments")
      else
        enr = person.primary_family.active_household.hbx_enrollments.where(:'aasm_state'.ne => 'shopping')
        if enr.size == 0
          @output_lines.push("No enrollments found by policy id")
        else
          @output_lines.push("Person HBX ID: #{@hbx_id}")
          enr.each do |hbx_em|
            @output_lines.push("Policy ID: #{hbx_em.hbx_id}")
            @output_lines.push("State: #{hbx_em.aasm_state}")
            @output_lines.push("Created at: #{hbx_em.created_at.to_s}")
            @output_lines.push("Effective on: #{hbx_em.effective_on.to_s}")
            @output_lines.push("Last updated at: #{hbx_em.updated_at.to_s}")

            user_id = hbx_em.updated_by_id || hbx_em.workflow_state_transitions.order_by(:'transition_at'.desc).limit(1).first&.user_id
            if user_id.nil?
              @output_lines.push("Last updated by: nil")
            else
              user = User.find(user_id)
              user_oim_id = user.oim_id
              @output_lines.push("Last updated by: #{user_oim_id.to_s}")
            end
          end
        end
      end

      ## respond
      slack = Slack::Incoming::Webhooks.new params[:response_url]
      slack.post @output_lines.join("\r\n")
    else
      ## error out
      ## respond
      slack = Slack::Incoming::Webhooks.new params[:response_url]
      slack.post "Slack user with username #{user_name} does not have permission to run policy-id-check. Please contact David Plappert with this error message to be given permission."
    end
  end
end
