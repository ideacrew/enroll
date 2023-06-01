# frozen_string_literal: true

# Class to build address worker to perform later
class AddressWorker
  include EventSource::Command
  include Sidekiq::Worker
  sidekiq_options retry: false

  # This method will be called when a job is enqueued
  # @param [Hash] params
  # @return [void]
  def perform(params)
    output = Operations::People::Addresses::Compare.new.call(params)

    if output.success?
      payload = output.success.deep_symbolize_keys!
      logger << "\n"
      logger.info(payload[:person_hbx_id]) { "*" * 100 }

      event_payload = build_event_payload(payload)
      result = ::Operations::Events::BuildAndPublish.new.call(event_payload)

      logger.info(payload[:person_hbx_id]) { [result, {event_payload: event_payload}] }
    else
      logger.debug(payload[:person_hbx_id]) { output }
    end
  rescue StandardError => e
    logger.error(params["person_hbx_id"]) { {Error: e.inspect} }
  end

  def build_event_payload(payload)
    headers = { correlation_id: payload[:person_hbx_id] }
    event_key = payload[:is_primary] ? "primary_member_address_relocated" : "member_address_relocated"

    {event_name: "events.families.family_members.#{event_key}", attributes: payload.to_h, headers: headers}
  end

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/address_worker_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
  end
end
