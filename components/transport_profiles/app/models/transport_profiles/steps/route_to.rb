require 'securerandom'

module TransportProfiles
  class Steps::RouteTo < Steps::Step

    def initialize(endpoint_key, file_name, gateway, destination_file_name: nil, source_credentials: nil)
      super("Route: ##{file_name} to #{endpoint_key}", gateway)
      @endpoint_key = endpoint_key
      @file_name = file_name
      @target_file_name = destination_file_name
      @source_credentials = resolve_source_credentials(source_credentials)
    end

    def resolve_source_credentials(source_credentials)
      return source_credentials unless source_credentials.kind_of?(Symbol)
      endpoints = ::TransportProfiles::WellKnownEndpoint.find_by_endpoint_key(source_credentials)
      raise ::TransportProfiles::EndpointNotFoundError unless endpoints.size > 0
      raise ::TransportProfiles::AmbiguousEndpointError, "More than one matching endpoint found" if endpoints.size > 1
      endpoints.first
    end

    def resolve_message_sources(process_context)
      found_name = @file_name.kind_of?(Symbol) ? process_context.get(@file_name) : @file_name
      if found_name.kind_of?(Array)
        found_name.map do |fn|
          fn.respond_to?(:scheme) ? fn : URI.parse(fn)
        end
      else
        found_name.respond_to?(:scheme) ? [found_name] : [URI.parse(found_name)]
      end
    end

    def execute(process_context)
      endpoints = ::TransportProfiles::WellKnownEndpoint.find_by_endpoint_key(@endpoint_key)
      raise ::TransportProfiles::EndpointNotFoundError unless endpoints.size > 0
      raise ::TransportProfiles::AmbiguousEndpointError, "More than one matching endpoint found" if endpoints.size > 1
      source_uris = resolve_message_sources(process_context)

      endpoint = endpoints.first

      source_uris.each do |file_uri|
        uri = complete_uri_for(endpoint, file_uri)

        message = ::TransportGateway::Message.new(from: file_uri, to: uri, destination_credentials: endpoint, source_credentials: @source_credentials)

        @gateway.send_message(message)
      end
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
