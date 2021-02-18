module BenefitSponsors
  module Observers
    class EmployerProfileObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def update(employer_profile, options={})
        address_or_phone_changed = employer_profile.office_locations.any? do |office_location|
          office_location.address.changes.present? && office_location.address.changes.keys.any?{ |key| ["address_1", "address_2", "city", "state", "zip"].include?(key)} ||
            office_location.phone.changes.present? && office_location.phone.changes.keys.any?{ |key| ["area_code", "number", "kind"].include?(key)}
        end
        return unless address_or_phone_changed
        notify("acapi.info.events.employer.address_changed", {employer_id: employer_profile.hbx_id, event_name: "address_changed"})
      end

      # def notifications_send(model_instance, new_model_event)
      #   if new_model_event.present? &&  new_model_event.is_a?(BenefitSponsors::ModelEvents::ModelEvent)
      #     if new_model_event.event_key == :generate_initial_employer_invoice
      #       employer_profile = new_model_event.klass_instance
      #       submitted_states = BenefitSponsors::BenefitApplications::BenefitApplication::SUBMITTED_STATES - [:termination_pending]
      #       benefit_application = employer_profile.benefit_applications.where(:aasm_state.in => submitted_states).sort_by(&:created_at).last
      #       deliver(recipient: employer_profile, event_object: benefit_application, notice_event: "generate_initial_employer_invoice") if benefit_application.present?
      #     end
      #   end
      # end

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
