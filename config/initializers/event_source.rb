# frozen_string_literal: true

# rubocop: disable Style/StderrPuts, Style/GlobalStdStream
EventSource.configure do |config|
  config.protocols = %w[amqp http]
  config.pub_sub_root =
    Pathname.pwd.join('app', 'event_source')
  config.server_key = ENV['RAILS_ENV'] # production, development# Rails.env.to_sym
  config.servers do |server|
    server.amqp do |rabbitmq|
      rabbitmq.host = ENV['RABBITMQ_HOST'] || "amqp://localhost"
      STDERR.puts rabbitmq.host
      rabbitmq.vhost = ENV['RABBITMQ_VHOST'] || "/"
      STDERR.puts rabbitmq.vhost
      rabbitmq.port = ENV['RABBITMQ_PORT'] || "5672"
      STDERR.puts rabbitmq.port
      rabbitmq.url = ENV['RABBITMQ_URL'] || "amqp://localhost:5672"
      STDERR.puts rabbitmq.url
      rabbitmq.user_name = ENV['RABBITMQ_USERNAME'] || "guest"
      STDERR.puts rabbitmq.user_name
      rabbitmq.password = ENV['RABBITMQ_PASSWORD'] || "guest"
      STDERR.puts rabbitmq.password
      # rabbitmq.url = "" # ENV['RABBITMQ_URL']
    end
  end
end
# rubocop: enable Style/StderrPuts, Style/GlobalStdStream

# dir = Rails.root.join('asyncapi_files')
#  EventSource.async_api_schemas = ::Dir[::File.join(dir, '**', '*')].sort.reject { |p| ::File.directory? p }.reduce([]) do |memo, file|
#     puts "----------#{file}"
#     memo << EventSource::AsyncApi::Operations::AsyncApiConf::LoadPath.new.call(path: file).success.to_h
#  end


EventSource.initialize!