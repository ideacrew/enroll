# frozen_string_literal: true

# Execute below code only if ENV['SERVICE_POD_NAME'] is set to enroll.frontend' or 'enroll.backend'
# Questions:
#   1. Do we want to make sure this only happens in Rails.env.production? This way we do not have to make code changes in Rails.env.test or Rails.env.development
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
  end

  async_api_resources = ::AcaEntities.async_api_config_find_by_service_name({ protocol: :amqp, service_name: nil }).success
  async_api_resources += ::AcaEntities.async_api_config_find_by_service_name({ protocol: :http, service_name: :enroll }).success

  # SERVICE_POD_NAME: 'enroll.frontend', 'enroll.backend'
  async_api_resources = if ENV['SERVICE_POD_NAME'] == 'enroll.frontend'
                          async_api_resources.reject do |async_api_resource|
                            (async_api_resource.to_s.include?('magi_medicaid.iap.benchmark_products.determine_slcsp') || async_api_resource.to_s.include?('magi_medicaid.#.eligibilities.#')) &&
                              !async_api_resource.to_s.include?("Publish configuration")
                          end
                        else
                          async_api_resources
                        end

  config.async_api_schemas = async_api_resources.collect { |resource| EventSource.build_async_api_resource(resource) }
end

# Initialize event_source only if ENV['SERVICE_POD_NAME'] is set to enroll.frontend' or 'enroll.backend'
EventSource.initialize!
