# frozen_string_literal: true

module Eligibilities
  module Eventable
    include EventSource::Command

    def self.included(base)
      base.extend ClassMethods
      base.include InstanceMethods

      base.class_eval { after_save :generate_evidence_updated_event }
    end

    module ClassMethods
    end

    module InstanceMethods
      def generate_evidence_updated_event
        event =
          event(
            eligibility_event_name,
            payload: {
              gid: self.to_global_id.uri,
              attributes: self.serializable_hash
            }
          )

        event.publish
      end
    end
  end
end
