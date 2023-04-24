module Subscribers
  class DefaultGaChanged < ::Acapi::Subscription
    def self.subscription_details
      ["acapi.info.events.broker.default_ga_changed"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      hbx_id = stringed_key_payload["broker_id"]
      pre_default_ga_id = BSON::ObjectId.from_string(stringed_key_payload["pre_default_ga_id"]) rescue ""
      person = Person.by_hbx_id(hbx_id).last
      broker_agency_profile = person.broker_role.broker_agency_profile rescue nil
      if broker_agency_profile&.default_general_agency_profile_id.present?
        plan_design_organizations = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner(broker_agency_profile.id).where(has_active_broker_relationship: true)
        service.assign_default_general_agency(broker_agency_profile, plan_design_organizations.map(&:id))
      end
    rescue Exception => e
      log("GA_ERROR: Unable to set default ga for #{e.try(:message)}", {:severity => "error"})
    end

    def service
      return @service if defined? @service

      @service = SponsoredBenefits::Services::GeneralAgencyManager.new(nil)
    end
  end
end
