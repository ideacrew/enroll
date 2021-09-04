# frozen_string_literal: true

# This job will be called with inputs OperationClassName and Payload.
# Example: This is used to renew a financial assistance application.
class FaApplicationJob < ActiveJob::Base
  queue_as :default

  def perform(operation_class_name, input_payload)
    result = operation_class_name.constantize.new.call(input_payload)
  rescue StandardError => e
    Rails.logger.error { "FaApplicationJob process error: #{e.backtrace}" }
  end
end
