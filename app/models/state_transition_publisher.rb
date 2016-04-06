module StateTransitionPublisher

  def self.included(base)
    base.class_eval do
      aasm do
        after_all_transitions :publish_transition
      end
    end
  end
​
  def publish_transition
    ApplicationEventMap.publish_friendly_event(resource_name, aasm.current_state, aasm.from_state, aasm.to_state, event_payload)
  end

end