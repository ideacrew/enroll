module Events
  class PoliciesController < ::ApplicationController
    include Acapi::Amqp::Responder

    def resource(connection, delivery_info, properties, body)
      reply_to = properties.reply_to
      headers = properties.headers || {}
      policy_id = headers.stringify_keys["policy_id"]
      policy = HbxEnrollment.by_hbx_id(policy_id).first
      if !policy.nil?
        response_payload = render_to_string "events/hbx_enrollment/policy", :formats => ["xml"], :locals => { :hbx_enrollment => policy }
        with_response_exchange(connection) do |ex|
          ex.publish(
            response_payload,
            {
              :routing_key => reply_to,
              :headers => {
                :return_status => "200",
                :policy_id => policy_id
              }
            }
          )
        end
      else
        with_response_exchange(connection) do |ex|
          ex.publish(
            "",
            {
              :routing_key => reply_to,
              :headers => {
                :return_status => "404",
                :policy_id => policy_id
              }
            }
          )
        end
      end
    end
  end
end
