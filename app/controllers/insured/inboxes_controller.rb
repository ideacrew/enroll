class Insured::InboxesController < InboxesController

  def find_inbox_provider
    @inbox_provider = Family.find(params["family_id"])
    @inbox_provider_name = @inbox_provider.primary_applicant.person.full_name
  end

  def successful_save_path
    broker_agencies_profile_path(@inbox_provider)
  end

end