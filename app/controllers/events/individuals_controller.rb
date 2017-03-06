module Events
  class IndividualsController < ::ApplicationController
    include Acapi::Amqp::Responder

    def resource(connection, delivery_info, properties, body)
      reply_to = properties.reply_to
      headers = properties.headers || {}
      individual_id = headers.stringify_keys["individual_id"]
      individual = Person.by_hbx_id(individual_id).first
      begin
        if !individual.nil?
          response_payload = render_to_string "created", :formats => ["xml"], :locals => { :individual => individual }
          with_response_exchange(connection) do |ex|
            ex.publish(
              response_payload,
              {
                :routing_key => reply_to,
                :headers => {
                  :return_status => "200",
                  :individual_id => individual_id
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
                  :individual_id => individual_id
                }
              }
            )
          end
        end
      rescue Exception=>e
        ex.publish(
          "#{individual_id} update failed - #{e.inspect}",
          {
            :routing_key => reply_to,
            :headers => {
              :return_status => "500"
              :individual_id => individual_id
            }
            })
      end
    end
  end
end
