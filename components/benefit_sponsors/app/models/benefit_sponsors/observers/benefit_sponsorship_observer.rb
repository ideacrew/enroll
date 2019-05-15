module BenefitSponsors
  module Observers
    class BenefitSponsorshipObserver
      include ::Acapi::Notifiers

      attr_accessor :notifier

      def notifications_send(model_instance, new_model_event)
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
