class Insured::InboxesController < InboxesController

  def find_inbox_provider
    family = Family.find(params["family_id"])
    @inbox_provider = family.primary_applicant.person
    @inbox_provider_name = @inbox_provider.full_name
  end

  def successful_save_path
    exchanges_hbx_profiles_root_path
  end

end