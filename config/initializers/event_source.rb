# frozen_string_literal: true
require 'faraday'

EventSource.configure do |config|
  config.protocols = %w[amqp http]
  config.pub_sub_root = Pathname.pwd.join('app', 'event_source')
  config.server_key = ENV['RAILS_ENV'] || Rails.env.to_sym
  config.app_name = :enroll

  config.servers do |server|
    server.amqp do |rabbitmq|
      rabbitmq.ref = 'amqp://rabbitmq:5672/event_source'
      rabbitmq.host = ENV['RABBITMQ_HOST'] || 'amqp://localhost'
      warn rabbitmq.host
      rabbitmq.vhost = ENV['RABBITMQ_VHOST'] || '/'
      warn rabbitmq.vhost
      rabbitmq.port = ENV['RABBITMQ_PORT'] || '5672'
      warn rabbitmq.port
      rabbitmq.url = ENV['RABBITMQ_URL'] || 'amqp://localhost:5672/'
      warn rabbitmq.url
      rabbitmq.user_name = ENV['RABBITMQ_USERNAME'] || 'guest'
      warn rabbitmq.user_name
      rabbitmq.password = ENV['RABBITMQ_PASSWORD'] || 'guest'
      warn rabbitmq.password
    end

    server.http do |http|
      http.ref = 'https://impl.hub.cms.gov/Imp1'
      http.url =
        ENV['RIDP_INITIAL_SERVICE_URL'] || 'https://impl.hub.cms.gov/Imp1'
      http.client_certificate do |client_cert|
        client_cert.client_certificate =
          ENV['RIDP_CLIENT_CERT_PATH'] ||
          File.join(File.dirname(__FILE__), '..', 'ridp_test_cert.pem')
        client_cert.client_key =
          ENV['RIDP_CLIENT_KEY_PATH'] ||
          File.join(File.dirname(__FILE__), '..', 'ridp_test_key.key')
      end
      http.default_content_type = 'application/soap+xml'
      http.soap do |soap|
        soap.user_name = ENV['RIDP_SERVICE_USERNAME'] || 'guest'
        soap.password = ENV['RIDP_SERVICE_PASSWORD'] || 'guest'
        soap.password_encoding = :digest
        soap.use_timestamp = true
        soap.timestamp_ttl = 60.seconds
      end

      http.delayed_queue do |queue|
        queue.retry_delay = 30 * 1000
        queue.retry_limit = 3
        queue.retry_exceptions = [StandardError, SystemStackError, Faraday::TimeoutError].freeze
        queue.event_name = 'events.delayed_queue.message_retry_requested'
        queue.publisher = 'Operations::Fdsh::RidpRepingService'
      end
    end
  end

  async_api_resources = ::AcaEntities.async_api_config_find_by_service_name({ protocol: :amqp, service_name: nil }).success
  async_api_resources += ::AcaEntities.async_api_config_find_by_service_name({ protocol: :http, service_name: :fdsh_gateway }).success

  config.async_api_schemas = async_api_resources.collect { |resource| EventSource.build_async_api_resource(resource) }
end

EventSource.initialize!
