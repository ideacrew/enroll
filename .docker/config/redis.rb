# frozen_string_literal: true

redis_host = ENV["REDIS_HOST_ENROLL"] || "localhost"

#rubocop:disable Style/GlobalVars
$redis = Resque.redis = Redis.new(:host => redis_host, :port => 6379)
#rubocop:enable Style/GlobalVars
