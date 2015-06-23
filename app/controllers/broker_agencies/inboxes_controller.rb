class BrokerAgencies::InboxesController < InboxesController

  def find_inbox_provider
    @inbox_provider = BrokerAgencyProfile.find(params["profile_id"])
    @inbox_provider_name = @inbox_provider.legal_name
  end

  def successful_save_path
    exchanges_hbx_profiles_root_path
  end

end