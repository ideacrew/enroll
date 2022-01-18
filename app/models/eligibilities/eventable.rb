# frozen_string_literal: true

module Eligibilities
  # Eventable module
  module Eventable
    include EventSource::Command

    def self.included(base)
      base.extend ClassMethods
      base.include InstanceMethods

      base.class_eval { after_save :generate_evidence_updated_event }
    end

    # class methods
    module ClassMethods
    end

    # instance methods
    module InstanceMethods
      def generate_evidence_updated_event
        return unless self.valid?

        global_id = self.to_global_id.uri
        global_id = self._parent.to_global_id.uri if self._parent.is_a?(
          FinancialAssistance::Applicant
        )

        event =
          event(
            eligibility_event_name,
            attributes: {
              gid: global_id,
              payload: self.serializable_hash
            }
          )

        event.success.publish if event.success?
      end
    end
  end
end
