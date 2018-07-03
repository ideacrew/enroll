module BenefitSponsors
  module Observers
    class OrganizationObserver
      include ::Acapi::Notifiers

      def update(instance, options = {})

        if instance.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
          notice_observer = Observers::NoticeObserver.new
          notice_observer.organization_create instance
        else
          return unless instance.employer_profile.present?

          event_names = Array.new

          BenefitSponsors::Organizations::Organization::FIELD_AND_EVENT_NAMES_MAP.each do |key, event_name|
            event_names << event_name if instance.changed_attributes.include?(key)
          end

          if event_names.any?
            event_names.each do |event_name|
              payload = {
                  employer_id: instance.hbx_id,
                  event_name: "#{event_name}"
              }
              notify("acapi.info.events.employer.#{event_name}", payload)
            end
          end
        end
      end
    end
  end
end
