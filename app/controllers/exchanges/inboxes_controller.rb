class Exchanges::InboxesController < InboxesController

  before_action :check_inbox_tab_enabled

  def find_inbox_provider
    authorize HbxProfile, :inbox?
    @inbox_provider = HbxProfile.find(params["id"])
    @inbox_provider_name = "System Admin"
  end

  def destroy
    @sent_box = true
    super
  end

  def show
    @sent_box = true
    super
  end

  private

  def check_inbox_tab_enabled
    redirect_to root_path, notice: "Inbox tab not enabled" unless EnrollRegistry.feature_enabled?(:inbox_tab)
  end
end
