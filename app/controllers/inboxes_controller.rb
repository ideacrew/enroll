class InboxesController < ApplicationController
  before_action :find_inbox_provider
  before_action :find_message, only: [:show, :destroy]
  before_action :set_inbox_and_assign_message, only: [:create]

  def new
    @new_message = @inbox_provider.inbox.messages.build
  end

  def create
    @new_message.folder = 'Inbox'

    @inbox.post_message(@new_message)
    if @inbox.save
      flash[:notice] = "Successfully sent message."
      redirect_to successful_save_path
    else
      render "new"
    end
  end

  def show
    @message.update_attributes(message_read: true)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def destroy
    #@message.destroy
    @message.update_attributes(folder: 'Deleted')
  end

  private
  def find_message
    @message = @inbox_provider.inbox.messages.by_message_id(params["message_id"]).to_a.first
  end

  def set_inbox_and_assign_message
    @inbox = @inbox_provider.inbox
    @new_message = Message.new(params.require(:message).permit!)
  end
end