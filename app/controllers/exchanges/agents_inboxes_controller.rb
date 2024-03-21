class Exchanges::AgentsInboxesController < InboxesController
  def find_inbox_provider
    authorize :agent, :inbox?
    @inbox_provider = current_user.person
    @inbox_provider_name = "Agent"
  end

  def destroy
    @sent_box = true
    super
  end

  def show
    @sent_box = true
    super
  end
end
