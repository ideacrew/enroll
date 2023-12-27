# frozen_string_literal: true

module Operations
  module EventLogs
    # Create Event Log entity
    class TrackableEvent
      include EventSource::Command

      attr_accessor :event_name,
                    :market_kind,
                    :payload,
                    :headers,
                    :subject,
                    :resource

      def initialize(event_name, options = {})
        @event_name = event_name
        @payload = options[:payload] || {}
        @headers = options[:headers] || {}
        @market_kind = "all"
      end

      def build_headers
        @headers[:subject_gid] ||= subject&.to_global_id&.to_s
        @headers[:resource_gid] ||= resource&.to_global_id&.to_s
        @headers[:market_kind] ||= market_kind
      end

      def validate
        raise "Subject is required" if headers[:subject_gid].blank?
        raise "Resource is required" if headers[:resource_gid].blank?
        raise "Market kind is required" if headers[:market_kind].blank?
      end

      def build
        build_headers
        validate
        event(
          event_name,
          attributes: payload,
          headers:
            headers.merge(
              event_category: category,
              event_outcome: action.titleize,
              trigger: action,
              event_time: DateTime.now,
              build_message: true
            )
        )
      end

      def category
        event_name.split(".")[-2]
      end

      def action
        event_name.split(".").last
      end
    end
  end
end
