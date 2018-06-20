module BenefitSponsors
  module Observers
    class EmployerStaffRoleObserver
      include Acapi::Notifiers
      extend Acapi::Notifiers

      def contact_changed?(staff_role, options={})
        notify(
          "acapi.info.events.employer.contact_changed",
          {employer_id: staff_role.hbx_id , event_name: "contact_changed"}
        ) if staff_role.changed?
      end
    end
  end
end
