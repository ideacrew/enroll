class InboxesController < ApplicationController
  before_action :find_inbox_provider
  before_action :set_inbox_and_assign_message, only: [:create]

  def new
    @new_message = @inbox_provider.inbox.messages.build
  end

  def create
    @inbox.post_message(@new_message)
    if @inbox.save
      flash[:notice] = "Successfully sent message."
      redirect_to successful_save_path
    else
      render "new"
    end
  end

  def show
    @message = @inbox_provider.inbox.messages.by_message_id(params["message_id"]).to_a.first
  end

  private

  def set_inbox_and_assign_message
    @inbox = @inbox_provider.inbox
    @new_message = Message.new(params.require(:message).permit!)
  end
end