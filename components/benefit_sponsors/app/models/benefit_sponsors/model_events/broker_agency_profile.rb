# frozen_string_literal: true

# rubocop:disable Lint/UselessAssignment
module BenefitSponsors
  module ModelEvents
    module BrokerAgencyProfile
      REGISTERED_EVENTS = [
        :default_general_agency_hired,
        :default_general_agency_fired
      ].freeze

      def notify_before_save
        event_options = {}
        if dafault_ga_update
          if default_ga_hired
            is_default_general_agency_hired = true
          else
            is_default_general_agency_fired = true
            event_options = { :old_general_agency_profile_id => changed_attributes["default_general_agency_profile_id"].to_s }
          end

           # This will be triggered when a broker with an existing default general agency selects a new one.
          if default_ga_fired
            is_default_general_agency_fired = true
            event_options = { :old_general_agency_profile_id => changed_attributes["default_general_agency_profile_id"].to_s }
          end
        end

        REGISTERED_EVENTS.each do |event|
          next unless (event_fired = instance_eval("is_" + event.to_s))

          event_options = {}
          notify_observers(ModelEvent.new(event, self, event_options))
        rescue StandardError => e
          Rails.logger.info { "BrokerAgencyProfile REGISTERED_EVENTS: #{event} unable to notify observers" }
          raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
        end
      end

      def dafault_ga_update
        changed? && valid? && changed_attributes.include?('default_general_agency_profile_id')
      end

      def default_ga_hired
        default_general_agency_profile_id.present?
      end

      def default_ga_fired
        default_general_agency_profile_id.present? && changed_attributes["default_general_agency_profile_id"].present?
      end
    end
  end
end

# rubocop:enable Lint/UselessAssignment
