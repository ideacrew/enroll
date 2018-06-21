module BenefitSponsors
  module Observers
    class BrokerAgencyAccountObserver
      include ::Acapi::Notifiers

      def broker_hired?(account, options={})
        if !account.persisted? && account.valid?
          profile = account.benefit_sponsorship.profile
          notify(
            "acapi.info.events.employer.broker_added",
            {
              employer_id: profile.hbx_id,
              event_name: "broker_added"
            }
          )
        end
      end

      def broker_fired?(account, options={})
        if account.persisted? && account.changed? && account.changed_attributes.include?("is_active")
          profile = account.benefit_sponsorship.profile
          notify(
            "acapi.info.events.employer.broker_terminated",
            {
              employer_id: profile.hbx_id,
              event_name: "broker_terminated"
            }
          )
        end
      end
    end
  end
end
