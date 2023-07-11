module AccessPolicies
  class GeneralAgencyProfile
    attr_accessor :user

    def initialize(user)
      @user = user
    end

    def authorize_new(controller)
      general_agency_profile_id = user.person.general_agency_staff_roles.last.general_agency_profile_id rescue nil
      if user.has_general_agency_staff_role? && general_agency_profile_id.present?
        controller.redirect_to_show(general_agency_profile_id)
      end
    end

    def authorize_index(controller)
      return true if user.has_hbx_staff_role? || user.has_csr_role? || user.has_broker_role?

      general_agency_profile_id = user.person.general_agency_staff_roles.last.general_agency_profile_id rescue nil
      if user.has_general_agency_staff_role? && general_agency_profile_id.present?
        controller.redirect_to_show(general_agency_profile_id)
      else
        controller.redirect_to_new
      end
    end

    def authorize_assign(controller, broker_agency_profile)
      return true if user.has_broker_role? || user.has_hbx_staff_role?

      controller.redirect_to_show(broker_agency_profile.id)
    end

    def authorize_set_default_ga(controller, broker_agency_profile)
      return true if user.has_hbx_staff_role? || user.has_broker_role?

      controller.redirect_to_show(broker_agency_profile.id)
    end

    def view_families(general_agency)
      return false unless user
      return true if user.has_hbx_staff_role?
      return false unless user.person

      staff_roles = user.person.general_agency_staff_roles.select(&:active?)

      staff_roles.any? do |sr|
        sr.general_agency_profile_id == general_agency.id
      end
    end
  end
end
