# frozen_string_literal: true

if ENV['SERVICE_POD_NAME'].present? && ENV['SERVICE_POD_NAME'] == 'enroll.backend'
  workers Integer(ENV['WEB_CONCURRENCY'] || 3)
  min_threads_count = Integer(ENV['RAILS_MIN_THREADS'] || 3)
  max_threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 6)
else
  max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
  min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
end

threads min_threads_count, max_threads_count

preload_app!

port        ENV['PORT'] || 3000
environment ENV['RAILS_ENV'] || 'development'

on_worker_boot do
  Mongoid::Clients.clients.each do |_name, client|
    client.close
    client.reconnect
  end
end

before_fork do
  Mongoid.disconnect_clients
end

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")
