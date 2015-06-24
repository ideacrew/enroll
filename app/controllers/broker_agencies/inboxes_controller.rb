class BrokerAgencies::InboxesController < InboxesController

  def new
    @inbox_provider_name = @broker_agency_provider.legal_name
    @inbox_to_name = 'Hbx Admin.'
    @inbox_provider = @broker_agency_provider
    super
  end

  def find_inbox_provider
    @broker_agency_provider = BrokerAgencyProfile.find(params["id"]||params['profile_id'])
    @inbox_provider = @broker_agency_provider
  end

  def successful_save_path
    exchanges_hbx_profiles_root_path
  end

end