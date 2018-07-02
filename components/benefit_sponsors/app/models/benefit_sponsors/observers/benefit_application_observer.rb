module BenefitSponsors
  module Observers
    class BenefitApplicationObserver
      include ::Acapi::Notifiers

      def on_update(model_event)
        observer = Observers::NoticeObserver.new
        observer.benefit_application_update model_event
      end
    end
  end
end
