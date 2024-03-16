class BrokerAgencyProfileContext
  attr_reader :user, :broker_agency_profile

  def initialize(user, broker_agency_profile)
    @user = user
    @broker_agency_profile = broker_agency_profile
  end
end