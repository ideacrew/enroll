module BrokerAgencies::ProfilesHelper
  def fein_display(broker_agency_profile)
    (broker_agency_profile.organization.is_fake_fein? && !current_user.has_broker_agency_staff_role?)|| (broker_agency_profile.organization.is_fake_fein? && current_user.has_hbx_staff_role?) || !broker_agency_profile.organization.is_fake_fein?
  end

  def disable_edit_broker_agency?(user)
    return false if user.has_hbx_staff_role?
    person = user.person
    person.broker_role.present? ? false : true
  end

  def can_show_destroy?(staff, broker_agency_profile)
    primary_broker = broker_agency_profile.primary_broker_role
    return true  if primary_broker.present? && (staff == primary_broker.person)
    false
  end

end