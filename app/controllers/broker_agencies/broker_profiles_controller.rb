class BrokerAgencies::BrokerProfilesController < ApplicationController
before_action :check_broker_role, only: [:new, :welcome]

private

def check_broker_role
  if current_user.has_broker_role?
    redirect_to broker_agencies_broker_profile_my_account(current_user.person.broker_agency_contact)
  end
end
