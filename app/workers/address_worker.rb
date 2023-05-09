# frozen_string_literal: true

# Class to build address worker to perform later
class AddressWorker
  include EventSource::Command
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(params)
    result = Operations::People::Addresses::Compare.new.call(params)

    return if result.failure?
    event_payload = build_event_payload(result.success)
    ::Operations::Events::BuildAndPublish.new.call(event_payload)
  end

  def build_event_payload(payload)
    headers = { correlation_id: payload["person_hbx_id"] }
    event_key = payload["is_primary"] ? "primary_member_address_relocated" :  "member_address_relocated"

    {event_name: "events.families.family_members.#{event_key}", attributes: { payload: payload.to_h }, headers: headers}
  end
end
