# frozen_string_literal: true

redis_host = ENV["REDIS_HOST_ENROLL"] || "localhost"

$redis = Resque.redis = Redis.new(:host => redis_host, :port => 6379) # rubocop:disable Style/GlobalVars
