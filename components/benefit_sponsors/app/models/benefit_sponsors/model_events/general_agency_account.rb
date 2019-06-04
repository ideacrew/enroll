# frozen_string_literal: true

# rubocop:disable Lint/UselessAssignment
module BenefitSponsors
  module ModelEvents
    module GeneralAgencyAccount
      REGISTERED_EVENTS = [
        :general_agency_hired,
        :general_agency_fired
      ].freeze

      def notify_before_save
        return if plan_design_organization.employer_profile.blank?

        is_general_agency_fired = true if is_ga_fired?
        is_general_agency_hired = true if is_ga_hired?

        REGISTERED_EVENTS.each do |event|
          next unless (event_fired = instance_eval("is_" + event.to_s))

          event_options = {}
          notify_observers(ModelEvent.new(event, self, event_options))
        rescue StandardError => e
          Rails.logger.info { "GeneralAgencyAccount REGISTERED_EVENTS: #{event} unable to notify observers" }
          raise e if Rails.env.test? # RSpec Expectation Not Met Error is getting rescued here
        end
      end

      def is_ga_fired?
        changed? && changed_attributes.include?('aasm_state') && changed_attributes.include?('end_on')
      end

      def is_ga_hired?
        valid? && changed_attributes.include?('broker_role_id') && changed_attributes.include?('start_on')
      end
    end
  end
end

# rubocop:enable Lint/UselessAssignment
