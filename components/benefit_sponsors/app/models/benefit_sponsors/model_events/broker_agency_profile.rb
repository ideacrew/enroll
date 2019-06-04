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
        if is_dafault_ga_updated?
          is_default_general_agency_hired = true if is_default_ga_hired?

          if is_default_ga_deleted? || is_default_ga_changed?
            is_default_general_agency_fired = true
            event_options = { :old_general_agency_profile_id => changed_attributes["default_general_agency_profile_id"].to_s }
          end
        end

        REGISTERED_EVENTS.each do |event|
          next unless (event_fired = instance_eval("is_" + event.to_s))

          notify_observers(ModelEvent.new(event, self, event_options))
        rescue StandardError => e
          Rails.logger.info { "BrokerAgencyProfile REGISTERED_EVENTS: #{event} unable to notify observers" }
          raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
        end
      end

      def is_dafault_ga_updated?
        changed? && valid? && changed_attributes.include?('default_general_agency_profile_id')
      end

      def is_default_ga_hired?
        default_general_agency_profile_id.present?
      end

      def is_default_ga_deleted?
        default_general_agency_profile_id.blank?
      end

      def is_default_ga_changed?
        default_general_agency_profile_id.present? && changed_attributes["default_general_agency_profile_id"].present?
      end
    end
  end
end

# rubocop:enable Lint/UselessAssignment
