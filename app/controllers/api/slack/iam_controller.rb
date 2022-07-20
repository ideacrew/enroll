class ApiSlackIamController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :require_login
  skip_before_action :authenticate_user_from_token!
  skip_before_action :authenticate_me!

  ## test in slack with:
  ## /iam-create-user email=user@domain.com first_name=Bob last_name=Smith password=secret username=BobSmith account_role=myTestRole
  ##
  ## copied from:
  ## https://jenkins.priv.dchbx.org/job/iam-create-user/configure
  def iam_create_user
    token = params[:token]
    user_name = params[:user_name]
    allowed_users = ENV['IAM_CREATE_USER_USERS'].split(',')

    ## validate the token AND make sure the user requesting it has privligdges
    if token == ENV['SLACK_API_TOKEN'] && allowed_users.include?(user_name)
      ## valid request
      ## var1=value1 var2=value2
      ## string is split into array split by spaces for processing
      inputs = params[:text].split(" ")

      args = {
        :email => nil,
        :first_name => nil,
        :last_name => nil,
        :password => nil,
        :username => nil,
        :system_flag => 1,
        :account_role => nil,
      }

      inputs.each do |input|
        parts = input.gsub(/\s+/, "").split("=")
        key = parts[0].to_sym
        value = parts[1]
        if args.key?(key)
          args[key] = value
        end
      end

      notify("acapi.info.events.account_management.creation_requested", args)

      @output_lines = []

      @output_lines.push("IAM Create User request sent.")

      ## respond
      slack = Slack::Incoming::Webhooks.new params[:response_url]
      slack.post @output_lines.join("\r\n")
    else
      ## error out
      ## respond
      slack = Slack::Incoming::Webhooks.new params[:response_url]
      slack.post "Slack user with username #{user_name} does not have permission to run iam-create-user. Please contact #{ENV['SLACK_API_ADMIN']} with this error message to be given permission."
    end
  end
end
