module BenefitSponsors
  module Observers
    class EmployerProfileObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def update(employer_profile, options={})
        employer_profile.office_locations.each do |office_location|
          notify("acapi.info.events.employer.address_changed", {employer_id: employer_profile.hbx_id, event_name: "address_changed"}) unless office_location.address.changes.empty?
        end
      end

      def notifications_send(model_instance, new_model_event)
        if new_model_event.present? &&  new_model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
          #add triggers
        end
      end

      private

      def initialize
        @notifier = BenefitSponsors::Services::NoticeService.new
      end

      def deliver(recipient:, event_object:, notice_event:, notice_params: {})
        notifier.deliver(recipient: recipient, event_object: event_object, notice_event: notice_event, notice_params: notice_params)
      end
    end
  end
end
