class BrokerAgencies::InboxesController < InboxesController

  def find_inbox_provider
    @broker_agency_provider = BrokerAgencyProfile.find(params["id"]||params['profile_id'])
    
  end

  def successful_save_path
    exchanges_hbx_profiles_root_path
  end

end