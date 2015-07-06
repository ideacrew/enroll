class Exchanges::InboxesController < InboxesController
	def find_inbox_provider
    @inbox_provider = HbxProfile.find(params["id"])
    @inbox_provider_name = "System Admin"
  end
end
