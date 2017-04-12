module Config::AcaConcern
  def individual_market_is_enabled?
    unless Settings.aca.market_kinds.include? 'individual'
     flash[:error] = "This Exchange does not support an individual marketplace"
     redirect_to root_path
    end
  end
end
