require 'uri'

module TransportGateway
  class Message

    attr_accessor :from, :to, :body

    #  @from
    #  @to 
    #  @body

    ## ACApi attributes
    #  @hbx_id
    #  @submitted_timestamp
    #  @authorization
    #  @service_status_type
    #  @message_id
    #  @originating_service
    #  @reply_to
    #  @fault_to
    #  @correlation_id
    #  @application_header_properties

    def initialize(**options)
      parse_options(options) unless options.empty?

      # Target must be a URI
      @to = to_uri(options[:to])
    end

  private 

    def to_uri(value)
      return if value.nil?
      value.is_a?(URI) ? value : URI.parse(value.to_s)
    end

    def parse_options(options)
      options.each { |k,v| instance_variable_set("@#{k}", v) }
    end

  end
end
