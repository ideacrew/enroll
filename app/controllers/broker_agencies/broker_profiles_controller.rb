class BrokerAgencies::BrokerProfilesController < ApplicationController
  before_action :check_broker_role, only: [:new, :welcome]

  def new

  end

  private

  def check_broker_role
    if current_user.has_broker_role?
      redirect_to broker_agencies_broker_profile_my_account(current_user.person.broker_agency_contact)
    else
      redirect_to root_path, :flash => { :error => "You do not belong to a broker agency" }
    end
  end

end
