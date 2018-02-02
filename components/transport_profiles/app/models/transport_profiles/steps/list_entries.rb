module TransportProfiles
  class Steps::ListEntries < Steps::Step
    def initialize(endpoint_key, result_key, gateway, &t_blk)
      super("List Entries at: #{endpoint_key}, store as: #{result_key}", gateway)
      @endpoint_key = endpoint_key
      @storage_key = result_key
      @transform_blk = t_blk
    end

    def execute(process_context)
      endpoints = ::TransportProfiles::WellKnownEndpoint.find_by_endpoint_key(@endpoint_key)
      raise ::TransportProfiles::EndpointNotFoundError unless endpoints.size > 0
      raise ::TransportProfiles::AmbiguousEndpointError, "More than one matching endpoint found" if endpoints.size > 1
      endpoint = endpoints.first
      query = TransportGateway::ResourceQuery.new({
        from: URI.parse(endpoint.uri),
        source_credentials: endpoint
      })
      entries = @gateway.list_entries(query)
      matching_entries = if !@transform_blk.nil?
                           @transform_blk.call(entries)
                         else
                           entries
                         end
      process_context.put(@storage_key, matching_entries.map(&:uri))
    end
  end
end
