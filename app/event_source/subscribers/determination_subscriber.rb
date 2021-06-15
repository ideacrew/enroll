# frozen_string_literal: true

module Subscribers
  # Subscriber will receive response payload from medicaid gateway and perform validation along with persisting the payload
  class DeterminationSubscriber
    include EventSource::Logging
    include ::EventSource::Subscriber[amqp: 'magi_medicaid.mitc.eligibilities']

    subscribe(:on_enroll_magi_medicaid_mitc_eligibilities) do |_headers, _payload|

      # TODO: update operation to persist response
      # result = Persist.new.call(payload)

      message = if result.success?
                  result.success
                else
                  result.failure
                end

      # TODO: log message
      puts "determination_subscriber_message: #{message}"
    rescue StandardError => e
      # TODO: log error message
      puts "determination_subscriber_error: #{e.backtrace}"
    end
  end
end