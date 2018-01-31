require 'securerandom'

module TransportProfiles
  class EndpointNotFoundError < StandardError; end
  class AmbiguousEndpointError < StandardError; end

  class Steps::RouteTo < Steps::Step

    def initialize(endpoint_key, file_name, gateway, destination_file_name: nil, source_credentials: nil)
      super("Route: ##{file_name} to #{endpoint_key}", gateway)
      @endpoint_key = endpoint_key
      @file_name = file_name
      @target_file_name = destination_file_name
      @source_credentials = source_credentials
    end

    def execute
      endpoints = ::TransportProfiles::WellKnownEndpoint.find_by_endpoint_key(@endpoint_key)
      raise ::TransportProfiles::EndpointKeyNotFoundError unless endpoints.size > 0
      raise ::TransportProfiles::AmbiguousEndpointError, "More than one matching endpoint found" if endpoints.size > 1
      file_uri = @file_name.respond_to?(:scheme) ? @file_name : URI.parse(@file_name)

      endpoint = endpoints.first
      uri = complete_uri_for(endpoint, file_uri)

      message = ::TransportGateway::Message.new(from: file_uri, to: uri, destination_credentials: endpoint, source_credentials: @source_credentials)

      @gateway.send_message(message)
    end

    def complete_uri_for(endpoint, file_uri)
      base_name = @target_file_name.blank? ? File.basename(file_uri.path) : @target_file_name
      endpoint_uri = URI.parse(endpoint.uri)
      case endpoint_uri.scheme
      when 's3'
        # The frequently changing bits of the UUID are at the end,
        # so flip it to make aws shard-happy
        random_portion = SecureRandom.uuid.gsub("-", "").reverse
        URI.join(endpoint.uri, random_portion + "_" + base_name)
      when 'sftp'
        URI.join(endpoint.uri, base_name) 
      end
    end
  end


end
