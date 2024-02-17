class Insured::InboxesController < InboxesController
  before_action :authorize_inbox

  def new
    @inbox_to_name = params['to']
    @inbox_provider_name = 'HBX ADMIN'
    super
  end

  def find_inbox_provider
    @inbox_provider = Person.find(params["id"])
    @inbox_provider_name = @inbox_provider.full_name
  end

  def successful_save_path
    exchanges_hbx_profiles_root_path
  end

  private

  def authorize_inbox
    binding.irb
  end
end
