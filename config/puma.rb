# frozen_string_literal: true

workers Integer(ENV['WEB_CONCURRENCY'] || 4)
min_threads_count = Integer(ENV['RAILS_MIN_THREADS'] || 5)
max_threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 10)
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
