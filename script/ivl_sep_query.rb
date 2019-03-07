start_time = Time.now - 17.minutes
end_time = Time.now

class IvlEnrollmentsPublisher
  extend Acapi::Notifiers

  def self.publish_action(action_name, hbx_id, action)
    reply_to = "dc0.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler"

    notify(
      action_name, {
      :reply_to => reply_to,
      :hbx_enrollment_id => hbx_id,
      :enrollment_action_uri => action
    })
  end
end

enrollment_query = Queries::IvlEnrollmentsQuery.new(start_time, end_time)

purchases = enrollment_query.purchases
terms = enrollment_query.terminations

purchase_event = "acapi.info.events.hbx_enrollment.coverage_selected"
purchases.each do |rec|
  pol_id = rec["_id"]
  Rails.logger.info "-----publishing #{pol_id}"

  if rec["enrollment_state"] == 'auto_renewing' || rec["enrollment_state"] == 'auto_renewing_contingent'
    IvlEnrollmentsPublisher.publish_action(purchase_event, pol_id, "urn:openhbx:terms:v1:enrollment#auto_renew")
  else
    IvlEnrollmentsPublisher.publish_action(purchase_event, pol_id, "urn:openhbx:terms:v1:enrollment#initial")
  end
end

term_event = "acapi.info.events.hbx_enrollment.terminated"
terms.each do |rec|
  pol_id = rec["_id"]
  Rails.logger.info "-----publishing #{pol_id}"
  IvlEnrollmentsPublisher.publish_action(term_event, pol_id, "urn:openhbx:terms:v1:enrollment#terminate_enrollment")
end
