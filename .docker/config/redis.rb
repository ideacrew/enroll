redis_host = ENV["REDIS_HOST_ENROLL"] || "localhost"

$redis = Resque.redis = Redis.new(:host => redis_host, :port => 6379)
