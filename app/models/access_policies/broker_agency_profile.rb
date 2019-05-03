module AccessPolicies
  class BrokerAgencyProfile
    attr_accessor :user

    def initialize(user)
      @user = user
    end

    def is_broker_staff_for_agency?(broker_profile)
      person = user.person
      return false unless person.broker_agency_staff_roles.present?
      broker_agency_profiles = person.broker_agency_staff_roles.map {|role| ::BrokerAgencyProfile.find(role.broker_agency_profile_id) }
      broker_agency_profiles.map(&:id).map(&:to_s).include?(broker_profile.to_s)
    end

    def authorize_edit(broker_profile, controller)
      return true if @user.has_hbx_staff_role? || is_broker_staff_for_agency?(broker_profile.id)
      return true if Person.staff_for_broker(broker_profile).include?(@user.person)
      controller.redirect_to_new and return
    end
  end
end
