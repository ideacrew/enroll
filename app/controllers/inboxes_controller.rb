class InboxesController < ApplicationController
  before_action :find_inbox_provider

  def new
    @inbox = Inbox.new
    @inbox.messages.build
  end

  def create
    params.require(:inbox).permit!
    inbox_record = @inbox_provider.inbox
    inbox_record.attributes = params["inbox"]
    if inbox_record.save
      flash[:notice] = "Successfully sent message."
      redirect_to successful_save_path
    else
      render "new"
    end
  end

  def index

  end
end
