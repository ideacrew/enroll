module BenefitSponsors
  module Observers
    class HbxEnrollmentObserver
      include ::Acapi::Notifiers

      def on_update(model_event)
        observer = Observers::NoticeObserver.new
        observer.hbx_enrollment_update model_event
      end
    end
  end
end
