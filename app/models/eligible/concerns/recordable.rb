# frozen_string_literal: true

module Eligible
  module Concerns
    # Mixin to record state transitions
    module Recordable

      def record_transition(_params)
        entity = Operations::Eligible::CreateStateHistory.new.call({
                                                                     effective_on: Date.today,
                                                                     is_eligible: self.class::ELIGIBLE_STATES.include?(aasm.to_state),
                                                                     from_state: aasm.from_state,
                                                                     to_state: aasm.to_state,
                                                                     event: aasm.current_event,
                                                                     transition_at: DateTime.now
                                                                   })

        if entity.success?
          self.state_histories << Eligible::StateHistory.new(entity.success.to_h)
        # else
        #   # failed...revert state transition
        end
      end
    end
  end
end
