require 'aws-sdk'
require "transport_gateway/engine"

module URI
  class S3 < Generic
    def region
      host
    end

    def key
      return nil if path.nil?
      path.gsub(/^\//, '')
    end

    def bucket
      userinfo
    end
  end

  @@schemes['S3'] = S3
end

module TransportGateway
end
