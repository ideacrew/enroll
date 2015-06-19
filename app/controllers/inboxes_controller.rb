class InboxesController < ApplicationController
  before_action :find_inbox_provider
  before_action :set_inbox_and_assign_message, only: [:create]

  def new
    @message = @inbox_provider.inbox.messages.build
  end

  def create
    if @inbox.post_message(@message)
      flash[:notice] = "Successfully sent message."
      redirect_to successful_save_path
    else
      render "new"
    end
  end

  def index

  end

  private

  def set_inbox_and_assign_message
    @inbox = @inbox_provider.inbox
    @message = @inbox.messages.build(params.require(:message).permit!)
  end
end