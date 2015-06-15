class Employers::InboxesController < ApplicationController
  before_action :find_employer

  def new
    @inbox = Inbox.new
    @inbox.messages.build
  end

  def create
    params.permit!
    inbox_record = @employer_profile.build_inbox
    inbox_record.attributes = params["inbox"]
    if inbox_record.save
      flash[:notice] = "Successfully sent message."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render "new"
    end
  end

  def index

  end

private
  def find_employer
    @employer_profile = EmployerProfile.find(params["employer_profile_id"])
  end
end