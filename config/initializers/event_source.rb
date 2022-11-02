# frozen_string_literal: true

if ENV['SERVICE_POD_NAME'].present? || !Rails.env.production?
  EventSource.configure do |config|
    config.protocols = %w[amqp]
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
    end

    async_api_resources = case ENV['SERVICE_POD_NAME']
                          when 'enroll.frontend'
                            ::AcaEntities.async_api_config_find_by_service_name({ protocol: :amqp, service_name: 'enroll', options: { load_subscriber_operations: false } }).success
                          when 'enroll.backend'
                            ::AcaEntities.async_api_config_find_by_service_name({ protocol: :amqp, service_name: nil }).success
                          else
                            []
                          end

    async_api_resources = ::AcaEntities.async_api_config_find_by_service_name({ protocol: :amqp, service_name: nil }).success unless Rails.env.production?

    config.async_api_schemas = async_api_resources.collect { |resource| EventSource.build_async_api_resource(resource) }
  end

  EventSource.initialize!
end
