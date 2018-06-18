module BenefitSponsors
  module Observers
    class EmployerProfileObserver
      include ::Acapi::Notifiers

      def update(employer_profile, options={})
        employer_profile.office_locations.each do |office_location|
          notify("acapi.info.events.employer.address_changed", {employer_id: employer_profile.hbx_id, event_name: "address_changed"}) unless office_location.address.changes.empty?
        end
      end
    end
  end
end
